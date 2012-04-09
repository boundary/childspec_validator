### Erlang Childspec Validator

Validate your childspecs before you use them. It attempts to find the most common mistakes in childspecs and let you know about them. This will ensure things start properly and increase the probability hot upgrades will be performed correctly.

It's an alertnative to supervisor:check_childspecs/1 but does basically the same thing.

### Usage

Provide the validate function a ChildSpec and make sure the module it references is compiled and on the path.

    % returns true or false
    childspec_validator:validate(YourChildSpec).
