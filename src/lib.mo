import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import EC "mo:base/ExperimentalCycles";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Error "mo:base/Error";

import ICRC3 "mo:icrc3-mo";

import Itertools "mo:itertools/Iter";

import Star "mo:star/star";
import Vec "mo:vector";
import TT "mo:timer-tool";
import ovsfixed "mo:ovs-fixed";

import Migration "./migrations";
import MigrationTypes "./migrations/types";

import ICRC104Service "./service";

/// The ICRC1 class defines the structure and functions necessary for creating and managing ICRC-1 compliant tokens on the Internet Computer. 
/// It encapsulates the state and behavior of a token ledger which includes transfer, mint, and burn functionalities, as well 
/// as metadata handling and tracking of transactions via ICRC-3 transaction logs.
module {

    /// Used to control debug printing for various actions.
    let debug_channel = {
      announce = true;
    };

    /// Exposes types from the migrations library to users of this module, allowing them to utilize these types in interacting 
    /// with instances of ICRC1 tokens and their respective attributes and actions.
    public type State =               MigrationTypes.State;


    // Imports from types to make code more readable
    public type CurrentState =        MigrationTypes.Current.State;
    public type Environment =         MigrationTypes.Current.Environment;

    public type RuleHandler =         MigrationTypes.Current.RuleHandler;
    public type HandleRuleEvent =     MigrationTypes.Current.HandleRuleEvent;
    public type InitArgs =            MigrationTypes.Current.InitArgs;
    public type Stats =               MigrationTypes.Current.Stats;
    public type RuleHandlerResponse = MigrationTypes.Current.RuleHandlerResponse;
    public type SNSValidationResponse = MigrationTypes.Current.SNSValidationResponse;
    public type RuleValidator =       MigrationTypes.Current.RuleValidator;
    public type AdvancedSettings =    MigrationTypes.Current.AdvancedSettings;

    /// Defines functions to create an initial state, versioning, and utilities for the token ledger. 
    /// These are direct mappings from the Migration types library to provide an easy-to-use API surface for users of the ICRC1 class.
    public func initialState() : State {#v0_0_0(#data)};
    public let currentStateVersion = #v0_1_0(#id);

    // Initializes the state with default or migrated data and sets up other utilities such as maps and vector data structures.
    /// Also initializes helper functions and constants like hashing, account equality checks, and comparisons.
    public let init = Migration.migrate;

    //convienence variables to make code more readable
    public let Map = MigrationTypes.Current.Map;
    public let Set = MigrationTypes.Current.Set;
    public let Vec = MigrationTypes.Current.Vector;


    public class ICRC104(stored: ?State, canister: Principal, environment: Environment){

      /// Initializes the ledger state with either a new state or a given state for migration. 
      /// This setup process involves internal data migration routines.
      var state : CurrentState = switch(stored){
        case(null) {
          let #v0_1_0(#data(foundState)) = init(initialState(),currentStateVersion, null, canister);
          foundState;
        };
        case(?val) {
          let #v0_1_0(#data(foundState)) = init(val,currentStateVersion, null, canister);
          foundState;
        };
      };

      /// Holds the list of listeners that are notified when a rule application request occurs
      private let ruleHandlerListeners = Map.new<Text, (RuleHandler, ?RuleValidator)>();

      //// Retrieves the full internal state of the component.
      
      ////
      //// Returns:
      //// - `CurrentState`: The complete state data of the ledger.
      public func get_state() : CurrentState {
        return state;
      };

      public func get_stats() : Stats {
        let buff = Buffer.Buffer<(Text, [(Text, Nat)])>(1);

        for(thisRule in Map.entries(state.callStats)){
          let subBuff = Map.toArray(thisRule.1);
          buff.add((thisRule.0, subBuff));
        };

        return {
          callStats = Buffer.toArray(buff);
          rules = Map.size(ruleHandlerListeners);
        } : Stats;
      };


      /// Returns the array of local transactions. Does not scale use icrc3-mo for scalable archives
      ///
      /// Returns:
      /// - `Vec<Transaction>`: A vector containing the local transactions recorded in the ledger.
      public func get_local_transactions() : Vec.Vector<ICRC3.Transaction> {
        return state.__fake_transactions;
      };

      /// Returns the current environment settings for the ledger.
      ///
      /// Returns:
      /// - `Environment`: The environment context in which the ledger operates, encapsulating properties 
      ///   like transfer fee calculation and timing functions.
      public func get_environment() : Environment {
        return environment;
      };

      /// `supported_standards`
      ///
      /// Provides a list of standards supported by the ledger, indicating compliance with various ICRC standards.
      ///
      /// Returns:
      /// `[SupportedStandard]`: An array of supported standards including their names and URLs.
      public func supported_standards() : [MigrationTypes.Current.SupportedStandard] {
          [{
            name = "ICRC-104";
            url = "https://github.com/dfinity/ICRC/ICRCs/ICRC-104";
          }];
      };

      /// `add_local_ledger`
      ///
      /// Adds a transaction to the local transaction log and returns its index.
      ///
      /// Parameters:
      /// - `tx`: The transaction to add to the log.
      ///
      /// Returns:
      /// `Nat`: The index at which the transaction was added in the local log.
      public func add_local_ledger(tx : ICRC3.Transaction) : Nat{
        Vec.add(state.__fake_transactions, tx);
        Vec.size(state.__fake_transactions) - 1;
      };

      public func addAdmin(principal: Principal) : (){
        ignore Set.put(state.admins, Set.phash, principal);
      };

      public func removeAdmin(principal: Principal) : (){
        ignore Set.put(state.admins, Set.phash, principal);
      };

      public func add_rule_handler_listener(name: Text, handler: RuleHandler, validator: ?RuleValidator) : Bool {
        ignore Map.put(ruleHandlerListeners, Map.thash, name, (handler, validator));
        true;
      };

      public func remove_rule_handler_listener(name: Text) : Bool {
        ignore Map.remove(ruleHandlerListeners, Map.thash, name);
        true;
      };

      private func registerStat(name: Text, stat: Text, value: Int) : () {
        //todo: only supports increasing  numbers
        D.print("registerStat" # name # stat # debug_show(value));
        let stats = switch(Map.get(state.callStats, Map.thash, name)){
          case(null) {
            let item = Map.new<Text, Nat>();
            ignore Map.put(state.callStats, Map.thash, name, item);
            item;
          };
          case(?val) val;
        };

        debug if(debug_channel.announce)  D.print("registerStat" # debug_show(stats));

        let posVal : Nat = Int.abs(value);

        ignore switch(Map.get(stats, Map.thash, stat)){
          case(null){
            debug if(debug_channel.announce) D.print("registerStat not found" # debug_show(stats));
            ignore Map.put(stats, Map.thash, stat, posVal);
          };
          case(?val){
            debug if(debug_channel.announce) D.print("registerStat found" # debug_show(val));
            ignore Map.put(stats, Map.thash, stat, val + posVal);
          };
        };

        debug if(debug_channel.announce) D.print("done registerStat" # debug_show(stats));

        return;
      };

      public func apply_rule_handler<system>(caller: Principal, rule: ICRC104Service.ApplyRuleRequest) : async* ICRC104Service.ApplyRuleResult {
        if(debug_channel.announce){
          D.print("apply_rule_handler" # debug_show(rule));
        };

        ensureTT<system>();
        state.icrc85.activeActions := state.icrc85.activeActions + 1;

        let ?handler = Map.get(ruleHandlerListeners, Map.thash, rule.rule_namespace) else {
          return #Err(#RuleSetNotFound);
        };

        let input = {
          rule with
          caller = caller;
        } : HandleRuleEvent;

        registerStat(rule.rule_namespace, "called", 1);

        debug if(debug_channel.announce) D.print("apply_rule_handler input" # debug_show(input));

        let result = try {
          await* handler.0<system>(input, false);
        } catch (err) {
          if(debug_channel.announce){
            D.print("apply_rule_handler error" # Error.message(err));
          };

          registerStat(rule.rule_namespace, "calledFailed", 1);
          return #Err(#ExecutionFailed(Error.message(err)));
        };

        if(debug_channel.announce){
          D.print("apply_rule_handler result" # debug_show(result));
        };

        //todo: do we need to clean up the state if the rule fails?
        switch(result){
          case(#err(_)){
            return #Err(#ExecutionFailed("Unreacahable err occured"));
          };
          case(#trappable(#simulation(val))) return #Err(#ExecutionFailed("Expected Application Results and Recieved Simulation Results"));
          case(#awaited(#simulation(val))) return #Err(#ExecutionFailed("Expected Application Results and Recieved Simulation Results"));
          case(#trappable(#apply(val))) return val;
          case(#awaited(#apply(val))) return val;
        };
      };

      public func validate_rule_handler<system>(caller: Principal, rule: ICRC104Service.ApplyRuleRequest) : async* SNSValidationResponse {

        let ?handler = Map.get(ruleHandlerListeners, Map.thash, rule.rule_namespace) else {
          return #Err("Rule not Found. " # rule.rule_namespace);
        };

        let ?validator = handler.1 else {
          return #Err("Validator not set for " # rule.rule_namespace);
        };

        registerStat(rule.rule_namespace, "validated", 1);

        let input = {
          rule with
          caller = caller;
        } : HandleRuleEvent;


        let result = try {
          await* validator<system>(input);
        } catch (err) {
          registerStat(rule.rule_namespace, "validationFailed", 1);
          return #Err("Validation Failed" # Error.message(err));
        };

        return result;
      };

      public func simulate_rule_handler<system>(caller: Principal, requested_caller: Principal, rule : ICRC104Service.ApplyRuleRequest) : async* ICRC104Service.SimulateRuleResult {

        ensureTT<system>();
        state.icrc85.activeActions := state.icrc85.activeActions + 1;

        let ?handler = Map.get(ruleHandlerListeners, Map.thash, rule.rule_namespace)  else {
          return #Err(#RuleSetNotFound);
        };

        let input = {
              rule with
              caller = requested_caller;
            };

        registerStat(rule.rule_namespace, "simulated", 1);

        let result = try{
          await* handler.0(input, true);
        } catch (err) {
          registerStat(rule.rule_namespace, "simulationFailed", 1);
          return #Err(#ExecutionFailed(Error.message(err)));
        };

        switch(result){
          case(#err(_)){
            return #Err(#ExecutionFailed("Unreacahable err occured"));
          };
          case(#trappable(#apply(val))) return #Err(#ExecutionFailed("Expected Simulation Results and Recieved Application Results" # debug_show(val)));
          case(#awaited(#apply(val))) return #Err(#ExecutionFailed("Expected Simulation Results and Recieved Application Results" # debug_show(val)));
          case(#trappable(#simulation(val))) return val;
          case(#awaited(#simulation(val))) return val;
        };

      };


      private func get_time() : Nat {
        Int.abs(Time.now());
      };

      private func scheduleCycleShare<system>() : async() {
        //check to see if it already exists
        debug if(debug_channel.announce) D.print("in schedule cycle share");
        switch(state.icrc85.nextCycleActionId){
          case(?val){
            switch(Map.get(tt<system>().getState().actionIdIndex, Map.nhash, val)){
              case(?time) {
                //already in the queue
                return;
              };
              case(null) {};
            };
          };
          case(null){};
        };

        let result = tt<system>().setActionSync<system>(get_time(), ({actionType = "icrc85:ovs:shareaction:icrc104"; params = Blob.fromArray([]);}));
        state.icrc85.nextCycleActionId := ?result.id;
      };

      private func handleIcrc85Action<system>(id: TT.ActionId, action: TT.Action) : async* Star.Star<TT.ActionId, TT.Error>{

        D.print("in handle timer async " # debug_show((id,action)));
        switch(action.actionType){
          case("icrc85:ovs:shareaction:icrc104"){
            await* shareCycles<system>();
            #awaited(id);
          };
          case(_) #trappable(id);
        };
      };

      private func shareCycles<system>() : async*(){
        debug if(debug_channel.announce) D.print("in share cycles ");
        let lastReportId = switch(state.icrc85.lastActionReported){
          case(?val) val;
          case(null) 0;
        };

        debug if(debug_channel.announce) D.print("last report id icrc104" # debug_show(lastReportId));

        let actions = if(state.icrc85.activeActions > 0){
          state.icrc85.activeActions;
        } else {1;};

        debug if(debug_channel.announce) D.print("actions 104" # debug_show(actions));

        var cyclesToShare = 1_000_000_000_000; //1 XDR

        if(actions > 0){
          let additional = Nat.div(actions, 10000);
          debug if(debug_channel.announce) D.print("additional " # debug_show(additional));
          cyclesToShare := cyclesToShare + (additional * 1_000_000_000_000);
          if(cyclesToShare > 100_000_000_000_000) cyclesToShare := 100_000_000_000_000;
        };

        debug if(debug_channel.announce) D.print("cycles to share" # debug_show(cyclesToShare));

        try{
          await* ovsfixed.shareCycles<system>({
            environment = do?{environment.advanced!.icrc85};
            namespace = "org.icdevs.libraries.icrc104";
            actions = 1;
            schedule = func <system>(period: Nat) : async* (){
              let result = tt<system>().setActionSync<system>(get_time() + period, {actionType = "icrc85:ovs:shareaction:icrc104"; params = Blob.fromArray([]);});
              state.icrc85.nextCycleActionId := ?result.id;
            };
            cycles = cyclesToShare;
          });
        } catch(e){
          debug if (debug_channel.announce) D.print("error sharing cycles" # Error.message(e));
        };

      };

      private var tt_ : ?TT.TimerTool = null;

      private func query_tt() : TT.TimerTool {
        switch(tt_){
          case(?val) val;
          case(null){
            debug if(debug_channel.announce) D.print("No timer tool set up");
            let foundClass = switch(environment.tt){
              case(?val) val;
              case(null){
                D.trap("No timer tool yet");
              };
            };
            foundClass;
          };
        };
      };

      let OneDay =  86_400_000_000_000;
      var _haveTimer : ?Bool = null;

      private func ensureTT<system>(){
        let haveTimer = switch(_haveTimer){
          case(?val) val;
          case(null){
            let result = (switch(environment.advanced){
                case(?val) {
                  switch(val.icrc85.kill_switch){
                    case(null) true;
                    case(?val) val;
                  };
                };
                case(null) true;
              });
            _haveTimer := ?result;
            result;
          };
        };
        debug if(debug_channel.announce) D.print(debug_show(("ensureTT", haveTimer)));
        if(haveTimer == true){
          ignore tt<system>();
        };
      };

      public func get_tt<system>() : TT.TimerTool {
        tt<system>();
      };

      public func get_advancedSettings() :  AdvancedSettings{
        environment.advanced;
      };

      private func tt<system>() : TT.TimerTool {
        switch(tt_){
          case(?val) val;
          case(null){
            
            let foundClass = switch(environment.tt){
              case(?val){
                tt_ := ?val;
                val;
              };
              case(null){
                //todo: recover from existing state?
                let timerState = switch(state.tt){
                  case(null) TT.init(TT.initialState(),#v0_1_0(#id), null, canister);
                  case(?val) TT.init(val,#v0_1_0(#id), null, canister);
                };

                state.tt := ?timerState;
                  let x = TT.TimerTool(?timerState, canister, {
                    advanced = switch(environment.advanced){
                      case(?val) {?{
                          icrc85 = ?val.icrc85
                        };
                      };
                      case(null) null;
                    };
                    reportError = null;
                    reportExecution = null;
                    syncUnsafe = null;
                    reportBatch = null;
                  });
                  tt_ := ?x;
                  x;
              };
            };

            foundClass.registerExecutionListenerAsync(?"icrc85:ovs:shareaction:icrc104", handleIcrc85Action : TT.ExecutionAsyncHandler);
            debug if(debug_channel.announce) D.print("Timer tool set up");
            ignore Timer.setTimer<system>(#nanoseconds(OneDay), scheduleCycleShare);

            foundClass;
          };
        };
      };



    };
};
