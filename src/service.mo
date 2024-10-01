import ICRC75Service "mo:icrc75-mo/service";

module {

  public type RuleSetNamespace = Text;

  public type ICRC75Change = {
      icrc75Canister: Principal;
      list: Text;
      changes: [ChangeDetail];
  };
  
  public type ChangeDetail = {
      #AddedMember: ICRC75Service.ListItem;    // Member added to the list
      #RemovedMember: ICRC75Service.ListItem;  // Member removed from the list
      #AddedPermission:  {Permission: ICRC75Service.Permission; member: ICRC75Service.ListItem};    // Permission added
      #RemovedPermission: {Permission: ICRC75Service.Permission; member:ICRC75Service.ListItem};  // Permission removed
      #CreateList: ICRC75Service.List;        // New list created
      #DeleteList: ICRC75Service.List;        // List deleted
      #ChangeListName: {oldName: ICRC75Service.List; newName: ICRC75Service.List }; // List renamed
      #UpdateMetadata: { path: Text; value: ?ICRC75Service.DataItem }; // Metadata updated
  };
    
  public type ApplyRuleRequest = {
    icrc75Canister : Principal;
    target_list: ICRC75Service.List;                     // The list to apply rules on
    members: [ICRC75Service.ListItem];                // Optional identity triggering the rule application
    rule_namespace: RuleSetNamespace;     // Namespace identifying the rule set to apply
    metadata: ?ICRC75Service.DataItemMap;                     // Optional metadata associated with the operation
  };

  public type ApplyError =  {
      #Unauthorized;
      #RuleSetNotFound;
      #InvalidRuleSetFormat: Text;
      #ExecutionFailed: Text;
  };

  public type ApplyRuleResult = {
    #Ok: {
      #RemoteTrx: {
        metadata: ICRC75Service.DataItemMap;
        transactions: [Nat];
      };
      #LocalTrx:{
        metadata: ICRC75Service.DataItemMap;
        transactions: [Nat];
      };
      #ICRC75Changes: {
          metadata: ICRC75Service.DataItemMap;
          changes:  [ICRC75Change];
      };
    };
    #Err: ApplyError;
  };

  public type SimulateRuleResult = {
    #Ok:  {
      metadata: ICRC75Service.DataItemMap;
      changes:  [ICRC75Change];
    };
    #Err: ApplyError;
  };

  public type service = actor {
    icrc104_apply_rules: (ApplyRuleRequest) -> async (ApplyRuleResult);
    icrc104_simulate_rules: (Principal, ApplyRuleRequest) -> async (SimulateRuleResult);
  };
};