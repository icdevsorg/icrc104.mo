// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead

import List "mo:base/List";
import MapLib "mo:map9/Map";
import SetLib "mo:map9/Set";
import Star "mo:star/star";
import VecLib "mo:vector";
import ICRC75 "mo:icrc75-mo";
import ICRC3 "mo:icrc3-mo";
import ICRC104Service "../../service";
import TT "mo:timer-tool";

module {

  /// `TxIndex`
  ///
  /// A type alias representing the index of a transaction in the transaction log.  
  public type TxIndex = Nat;

  public let Vector = VecLib;
  public let Map = MapLib;
  public let Set = SetLib;

  public type ICRC75Canister = Principal;
  public type List = ICRC75.List;
  public type ListItem = ICRC75.ListItem;
  public type RuleSetNamespace = Text;
  public type ICRC16 = ICRC75.DataItem;
  public type Metadata = ICRC75.ICRC16Map;

  public type HandleRuleEvent = {
    caller: Principal;
    icrc75Canister: ICRC75Canister;
    rule_namespace: RuleSetNamespace;
    members: [ListItem];
    target_list: List;
    metadata: ?ICRC75.ICRC16Map;
  };

  public type RuleHandler = <system>(HandleRuleEvent, Bool) -> async* Star.Star<RuleHandlerResponse, ()>;

  public type SNSValidationResponse = {
    #Ok: Text;
    #Err: Text;
  };

  public type RuleValidator = <system>(HandleRuleEvent) -> async* SNSValidationResponse;

  public type RuleHandlerResponse = {
    #simulation:  ICRC104Service.SimulateRuleResult;
    #apply: ICRC104Service.ApplyRuleResult;
  };


  /// `State`
  ///
  /// Represents the mutable state of the ICRC-1 token ledger, including all necessary variables for its operation.
  /// It records various aspects of the ledger, like burned and minted tokens, time restrictions for transactions,
  /// account information, and environmental settings for fee calculations and more.
  public type State = {
     var admins : Set.Set<Principal>; //admins can apply rules
     var callStats : Map.Map<Text, Map.Map<Text, Nat>>;
     var __fake_transactions : VecLib.Vector<ICRC3.Transaction>;
     icrc85: {
      var nextCycleActionId: ?Nat;
      var lastActionReported: ?Nat;
      var activeActions: Nat;
    };
    var tt : ?TT.State;
  };

  /// `Stats`
  ///
  /// Represents collected statistics about the ledger, such as the total number of accounts.
  public type Stats = {
    rules: Nat;
    callStats: [(Text, [(Text, Nat)])];
  };

   public type ICRC85Options = {
    kill_switch: ?Bool;
    handler: ?(([(Text, ICRC75.ICRC16Map)]) -> ());
    period: ?Nat;
    tree: ?[Text];
    asset: ?Text;
    platform: ?Text;
    collector: ?Principal;
  };

  public type AdvancedSettings = ?{
      icrc85 : ICRC85Options;
    };

  /// `Environment`
  ///
  /// A record that encapsulates various external dependencies and settings that the ledger relies on
  /// for fee calculations, timestamp retrieval, and inter-canister communication.
  /// can_transfer supports evaluating the transfer from both sync and async function.
  public type Environment = {
    add_ledger_transaction: ?(<system>(ICRC3.Value, ?ICRC3.Value) -> Nat);
    advanced : AdvancedSettings;
    tt : ?TT.TimerTool;
  };

  /// `SupportedStandard`
  ///
  /// Describes a standard that the token ledger supports, with its name and URL for more information.
  public type SupportedStandard = {
      name : Text;
      url : Text;
  };

  /// `TxLog`
  ///
  /// A vector holding a log of transactions for the ledger.
  public type TxLog = Vector.Vector<ICRC3.Transaction>;

  /// `MetaDatum`
  ///
  /// Represents a single metadata entry as a key-value pair.
  public type ICRC3MetaDatum = (Text, ICRC3.Value);

  /// `MetaData`
  ///
  /// A collection of metadata entries in a `Value` variant format, encapsulating settings and properties related to the ledger.
  public type ICRC3MetaData = ICRC3.Value;

  /// `InitArgs`
  ///
  /// Encapsulates initial arguments for setting up an ICRC-1 token canister, including token details and operational constraints.
  public type InitArgs = ?{
    callStats: ?[(Text, [(Text, Nat)])];
    admins: ?[Principal];
    local_transactions: [ICRC3.Transaction];
  };
};