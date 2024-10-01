import D "mo:base/Debug";
import Opt "mo:base/Option";
import Itertools "mo:itertools/Iter";
import Map "mo:map9/Map";
import Set "mo:map9/Set";
import Vec "mo:vector";
import MigrationTypes "../types";
import ICRC3 "mo:icrc3-mo";
import v0_1_0 "types";

module {


  public func upgrade(prevmigration_state: MigrationTypes.State, args: MigrationTypes.Args, caller: Principal): MigrationTypes.State {

    

    let initAdmins = do?{args!.admins!};

    let admins = switch(initAdmins){
      case(null){
        let new = Set.new<Principal>();
        ignore Set.put<Principal>(new, Set.phash, caller);
        new;
      };
      case(?admins){
        Set.fromIter<Principal>(admins.vals(), Set.phash);
      };
    };

    

    let argsCallStats = do?{args!.callStats!};

    let callStats = switch(argsCallStats){
      case(null){
        Map.new<Text, Map.Map<Text, Nat>>();
      };
      case(?callStats){
        let newStats = Map.new<Text, Map.Map<Text, Nat>>();
        for(thisItem in callStats.vals()){
          let aStat = Map.new<Text, Nat>();
          for(thisStat in thisItem.1.vals()){
            ignore Map.put<Text, Nat>(aStat, Map.thash, thisStat.0, thisStat.1);
          };
          ignore Map.put<Text, Map.Map<Text, Nat>>(newStats, Map.thash, thisItem.0, aStat);
        };
        newStats;
      };
    };
    
    

    let state : MigrationTypes.Current.State = {
      var admins = admins;
      var callStats =callStats;
      var __fake_transactions = Vec.new<ICRC3.Transaction>();
      icrc85 = {
        var nextCycleActionId = null;
        var lastActionReported = null;
        var activeActions = 0;
      };
      var tt = null;
    };

    

    return #v0_1_0(#data(state));
  };

  public func downgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args, caller: Principal): MigrationTypes.State {

    return #v0_0_0(#data);
  };

};