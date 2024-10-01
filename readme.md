# ICRC-104 Motoko Implementation

Welcome to the `icrc104.mo` project, a Motoko implementation of the **ICRC-104: Rule-Based Membership Manager Standard**. This project provides a modular, flexible, and interoperable solution for managing and manipulating memberships within lists as defined by the **ICRC-75 Minimal Membership Standard**.

## Overview

**ICRC-104** establishes a generic protocol for managing and manipulating memberships within lists defined by the **ICRC-75 Minimal Membership Standard**. This standard allows developers to create scalable and adaptable applications by applying customizable rule sets to membership lists, enabling operations such as role rotation, house sorting, and other membership-driven functionalities.

This project provides a Motoko module that implements the ICRC-104 standard, allowing for seamless integration with existing ICRC-75 canisters and other applications on the Internet Computer.

## Features

- **Modular Design**: Easily integrates with existing systems without heavy dependencies.
- **Flexible Rule Management**: Define and apply diverse rule sets without strict schema enforcement.
- **Interoperability**: Seamless interaction between different canisters implementing ICRC standards.
- **Scalability**: Efficiently handle operations on large membership lists.
- **ICRC-3 Transaction Logging**: Supports transaction logging for auditability and traceability.

## Getting Started

### Prerequisites

- [DFINITY SDK - dfx](https://internetcomputer.org/docs/current/developer-docs/getting-started/install/) installed.
- Basic knowledge of [Motoko](https://internetcomputer.org/docs/current/motoko/main/getting-started/motoko-introduction) programming language.
- [Mops.one](https://mops.one/) package manager
- Familiarity with the Internet Computer ecosystem.

### Installation

Install the code using Mops and navigate to the project directory:

```bash
mops add icrc104-mo
mops install
```

## Usage

### Initialization

To initialize the ICRC-104 module within your canister, you can create an instance of the `ICRC104` class. Here's an example based on the provided code:

```motoko
import ICRC104 "mo:icrc104-mo";

actor class Token(init_args : ICRC104.InitArgs) = this {
    // Initialize the ICRC-104 instance
    stable let icrc104_migration_state = ICRC104.init(ICRC104.initialState(), #v0_1_0(#id), init_args, _owner);

    let #v0_1_0(#data(icrc104_state_current)) = icrc104_migration_state;

    private var _icrc104 : ?ICRC104.ICRC104 = null;

    private func get_icrc104_environment() : ICRC104.Environment {
    {
      add_ledger_transaction = null; //wire up ICRC3 if desired
      advanced = null; //handle ICRC-85 open value sharing
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
};
```

### Applying Rules

To apply a rule set to a target list, use the `apply_rule_handler` method:

```motoko
let result = await icrc104_instance.apply_rule_handler(caller, {
    icrc75Canister = <ICRC-75 Canister Principal>;
    target_list = <ICRC75 Target List>;
    members = [<ListItem>]; //optional target members
    rule_namespace = <RuleSetNamespace>; //namespace of the rule
    metadata = null; //optional ingoing metadata
});
```

### Simulating Rules

To simulate the application of a rule set without making actual changes. Simulation is optional and may or may not be supported by the component processing the change. Developers are responsible for preventing the commit of data during a simulation:

```motoko
let simulationResult = await icrc104_instance.simulate_rule_handler(caller, requestedCaller, {
    icrc75Canister = <ICRC-75 Canister Principal>;
    target_list = <Target List>;
    members = [<ListItem>];
    rule_namespace = <RuleSetNamespace>;
    metadata = null;
});
```

## API Reference

### Core Methods

#### `apply_rule_handler`

Applies a set of rules from a specified namespace to a target membership list.

```motoko
public func apply_rule_handler<system>(
    caller: Principal,
    rule: ICRC104Service.ApplyRuleRequest
) : async* ICRC104Service.ApplyRuleResult;
```

- **Parameters**:
  - `caller`: The principal initiating the rule application.
  - `rule`: The rule application request containing details like `icrc75Canister`, `target_list`, `members`, `rule_namespace`, and `metadata`.

- **Returns**: An `ApplyRuleResult` indicating success or failure.

#### `simulate_rule_handler`

Simulates the application of a rule set without making changes.

```motoko
public func simulate_rule_handler<system>(
    caller: Principal,
    requested_caller: Principal,
    rule: ICRC104Service.ApplyRuleRequest
) : async* ICRC104Service.SimulateRuleResult;
```

- **Parameters**:
  - `caller`: The principal making the simulation request.
  - `requested_caller`: The principal to simulate as.
  - `rule`: The rule application request.

- **Returns**: A `SimulateRuleResult` with the simulated changes.

### Types

#### `ApplyRuleRequest`

```motoko
public type ApplyRuleRequest = {
    icrc75Canister : Principal;
    target_list: ICRC75Service.List;
    members: [ICRC75Service.ListItem];
    rule_namespace: RuleSetNamespace;
    metadata: ?ICRC75Service.DataItemMap;
};
```

#### `ApplyRuleResult`

```motoko
public type ApplyRuleResult = {
    #Ok: {
        #RemoteTrx: { metadata: DataItemMap; transactions: [Nat]; };
        #LocalTrx: { metadata: DataItemMap; transactions: [Nat]; };
        #ICRC75Changes: { metadata: DataItemMap; changes: [ICRC75Change]; };
    };
    #Err: ApplyError;
};
```

#### `SimulateRuleResult`

```motoko
public type SimulateRuleResult = {
    #Ok: { metadata: DataItemMap; changes: [ICRC75Change]; };
    #Err: ApplyError;
};
```

## Supported Standards

The `icrc104.mo` module complies with the following standards:

- **ICRC-104**: Rule-Based Membership Manager Standard
- **ICRC-75**: Minimal Membership Standard
- **ICRC-3**: Transaction Logging Standard (Optional)
- **ICRC-10**: Supported Standards Interface

The `supported_standards` method returns the standards supported by the ledger:

```motoko
public func supported_standards() : [MigrationTypes.Current.SupportedStandard] {
    [{
        name = "ICRC-104";
        url = "https://github.com/dfinity/ICRC/ICRCs/ICRC-104";
    }];
};
```

## Dependencies

The `icrc104.mo` module depends on several libraries and modules:

- Motoko Base Library
- External Libraries:
  - `ICRC3` (`mo:icrc3-mo`)
  - `Itertools` (`mo:itertools/Iter`)
  - `Star` (`mo:star/star`)
  - `Vec` (`mo:vector`)
  - `ICRC75Service`

Ensure that these dependencies are correctly referenced and accessible in your project.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -am 'Add your feature'`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Create a new Pull Request.

Please make sure to update tests as appropriate.



## License

This project is licensed under the [MIT License](LICENSE).

## OVS Default Behavior

This motoko class has a default OVS behavior that sends cycles to the developer to provide funding for maintenance and continued development. In accordance with the OVS specification and ICRC85, this behavior may be overridden by another OVS sharing heuristic or turned off. We encourage all users to implement some form of OVS sharing as it helps us provide quality software and support to the community.

Default behavior: 1 XDR per 10000 list actions processed per month up to 100 XDR;

Default Beneficiary: ICDevs.org

Dependent Libraries: 
 - https://mops.one/timer-tool
 - https://mops.one/icrc75-mo

 # AstroFlora

![AstroFlora](AF.png "AstroFlora")

...coming soon....

