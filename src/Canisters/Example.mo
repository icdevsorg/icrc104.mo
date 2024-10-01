///This is a naieve token implementation and shows the minimum possible implementation. It does not provide archiving and will not scale.
///Please see https://github.com/PanIndustrial-Org/ICRC_fungible for a full featured implementation

import Array "mo:base/Array";
import D "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

import Vec "mo:vector";

import ICRC104 "..";
import ICRC10 "mo:icrc10-mo";


shared ({ caller = _owner }) actor class Token  (
    init_args : ICRC104.InitArgs,
) = this{

    let icrc104_args : ICRC104.InitArgs = null;

    stable let icrc104_migration_state = ICRC104.init(ICRC104.initialState(), #v0_1_0(#id), init_args, _owner);

    let #v0_1_0(#data(icrc104_state_current)) = icrc104_migration_state;

    private var _icrc104 : ?ICRC104.ICRC104 = null;

    private func get_icrc104_state() : ICRC104.CurrentState {
      return icrc104_state_current;
    };

    private func get_icrc104_environment() : ICRC104.Environment {
    {
      add_ledger_transaction = null;
      advanced = null;
      tt = null;
    };
  };

  func icrc104() : ICRC104.ICRC104 {
    switch(_icrc104){
      case(null){
        let initclass : ICRC104.ICRC104 = ICRC104.ICRC104(?icrc104_migration_state, Principal.fromActor(this), get_icrc104_environment());
        _icrc104 := ?initclass;
        initclass;
      };
      case(?val) val;
    };
  };

  stable var icrc10 = ICRC10.initCollection();

  public shared(msg) func init() : async() {
    for(thisStandard in icrc104().supported_standards().vals()){
      ICRC10.register(icrc10, thisStandard);
    };
  };

};



