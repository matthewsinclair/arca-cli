---
verblock: "2024-05-02:v0.1: Matthew Sinclair - Initial version"
---

# Arca CLI Development Journal

##### 20250127

Resuscitated to help with ICPZero.

**Logs**

* f7c71cf - Updatred for Elixir 1.18 (4 seconds ago) <Matthew Sinclair>
* e5a000b - Updatred for Elixir 1.18 (40 minutes ago) <Matthew Sinclair>
* c4c5b83 - Updatred for Elixir 1.18 (85 minutes ago) <Matthew Sinclair>
* 3846c1e - Updatred for Elixir 1.18 (86 minutes ago) <Matthew Sinclair>
* 0d74d9a - Resuscitated to help with ICPZero (2 hours ago) <Matthew Sinclair>
* 6252ba5 - Resuscitated to help with ICPZero (2 hours ago) <Matthew Sinclair>
* c7ed464 - Resuscitated to help with ICPZero (2 hours ago) <Matthew Sinclair>
* 99a2280 - Resuscitated to help with ICPZero (2 hours ago) <Matthew Sinclair>

##### 20240627

Added in support for readline on the repl script

**Logs**

* 358a5fa Added an rlwrap wrapper for scripts/repl to use rlwrap if it is available
* 6046c20 Added an rlwrap wrapper for scripts/repl to use rlwrap if it is available
* 12d6f96 Journal
* fc2f991 Journal
* b158022 Hacking randomly
* 4b2e72d Journal
* c07bb4b An attempt to ressurect an old C readline NIF thingamagic

##### 20240621

**Logs**

* 2e85df6 Fixed a double-up with output for sub-commands. Updated deps.

##### 20240616

**Logs**

* 2d1e78a Removed Arca-specific text from About command
* d523669 Backlog
* 2bae9c1 Updated docs
* 5762da5 Journal

##### 20240614

CLI with sub commands is now (more or less) working.

**Logs**

* 1c869b7 Journal
* 19fd1e9 Went for a drive. Thought about it all subconsciously. Came back. Spent 30 mins. Now it's all working. Yay.
* c9488cb Doing a bit of name refactoring to tidy up SubCommand
* 3912743 Doing a bit of name refactoring to tidy up SubCommand
* 335922a Subcommands are basically working, just need to refactor into a macro to reduce syntax
* bc42f59 Added test stub in Eg.CLI for nested sub-command Eg.CLI.EgsubCommand
* e9672ea Journal

##### 20240614

Built a trivial example of a full Arca.CLI config to show how it works and dded some tests for the example.
Started to work on a SubCommand to allow for a similarly simple config for nested CLI commands (but that isn't working yet).

**Logs**

* eecc5e7 Journal
* d453d51 Updated docs and doctests for Utils
* 5a1b685 Added in a test for a trivial CLI config (as an example). Added a util to get the current fn's module and name as a string. Updated deps.

##### 20240613

Bumped to Elixir 1.17.

**Logs**

* 00c5a82 Bumped to Elixir 1.17. Updated deps.

##### 20240610

Added SysCommand to allow for running OS commands from within the CLI.

**Logs**

* 2711f03 Added SysCommand to allow for running OS commands from within the CLI
* 9f3341c Swapped around duration, result in Utils.timer (for readability)

##### 20240610

Added in a simple Timer utility to time how long a function takes to run.

**Logs**

* 61fb376 Added Utils.timer/1 to time how long a function takes to execute
* 75d88f9 Journal

##### 20240609

Continuing to make Arca.CLI work more nicely with clients. Tidied up the command handler dispatch so that it generically looks thru all registered commands to work out which command to fire.

**Logs**

* 347ce99 Journal
* 7fe827b Fixed Arca.CLI so that it generically finds the command to execute
* 5882871 Journal
* e28fe0f First contact with someone using Arca.CLI needs a few tweaks
* 7138829 Now it is working.
* 3357340 Now it is working.
* f1a9228 Weird. A test is failing for no reason.

##### 20240608

Making Arca.CLI work with clients.

**Logs**

* e28fe0f First contact with someone using Arca.CLI needs a few tweaks

##### 20240601

Made Coordinator handle either a single module or a list of modules, to which setup is applied to each

**Logs**

* a4361a6 Docs
* f4ff882 Fixed the configuration to handle chaining of Configurators with protection for doing dumb things
* ee3f5f5 Fixed the configuration to handle chaining of Configurators with protection for doing dumb things
* ed7b014 Oops. Noticed some of the config attrs were not properly unquoted.
* e8e2969 Safe check-in before modifying Coordinator to handle multiple Configurators. Updated deps.

##### 20240529

Continuing the push to turn Command into a macro: done!
Converted all of the base Commands into the macro-using versions of same.

**Logs**

* e69bc39 Docs. Updated deps.
* 8212ff3 Fixed the rest of the Configurators config params
* 26affdf Ported the Configurator to a use_able macro
* 5992726 Docs
* e5fe3c0 Normalising module, function, and file names for consistency
* df962b0 Using Base for module macro implementations (ie Command.Base and Configurator.Base) and *Behaviour for protocol definition (ie ConfiguratorBehavior and CommandBehaviour)
* 64f0a7b Docs
* b1874aa Renamed Cfg to CfgBehaviour because, well, that's what it is.
* 55477d8 Renamed CommandCfg to CommandBehaviour because, well, that's what it is.
* 4e6a548 Docs
* 1374867 Docs
* a29c6dc Docs
* d8525c9 Ported StatusCommand to Command macro
* 0ff0c9c Ported SettingsCommand to Command macro
* dc3bdb0 Ported ReplCommand to Command macro
* 3eede15 Ported RedoCommand to Command macro
* 95d7cee Ported HistoryCommand to Command macro
* 36d444f Ported GetCommand to Command macro
* aaf7d67 Ported FlushCommand to Command macro
* b27559d Turned Command into a usa_able DSL for commands. Ported AboutCommand to new format. Seems to be working. Updated deps.
* 82cf8c1 Added in Command and CommandTest (skeletons) for the command DSL
* f7088e8 Fixed Cfg.inject_subcommands/2 so that successive injects keep the keywords from the last one injected
* f024861 Fixed Cfg.inject_subcommands/2 so that successive injects keep the keywords from the last one injected
* f8c25b6 Made Cfg.inject_subcommands/2 more Elixir-idiomatic
* ad3b21e Added a test for chaining multipe configs together
* 1571578 Added a test for chaining multipe configs together
* f1ae688 Removed the old Optimus config
* ce5b27c Moved all of the CLI's standard commands over to Configurator
* 1f0d353 Fixed extraneous help output when user just presses enter
* 869843f Added in FlushCommand
* 321cc4d Basic CommandBehaviour behaviour in place (for AboutCommand)

##### 20240528

Big push to get the Coordinator stuff working so that I can refactor CLI into STL, LL, etc.

**Logs**

* f024861 Fixed Cfg.inject_subcommands/2 so that successive injects keep the keywords from the last one injected
* f8c25b6 Made Cfg.inject_subcommands/2 more Elixir-idiomatic
* ad3b21e Added a test for chaining multipe configs together
* 1571578 Added a test for chaining multipe configs together
* f1ae688 Removed the old Optimus config
* ce5b27c Moved all of the CLI's standard commands over to Configurator
* 1f0d353 Fixed extraneous help output when user just presses enter
* 869843f Added in FlushCommand
* 321cc4d Basic CommandBehaviour behaviour in place (for AboutCommand)
* 54cd442 Not comfortable with the Configurator module names, take 2
* a4bc3c9 Added a doc/backlog.md file to cli and config

##### 20240522

Made History supervised by HistorySupervisor (see: <https://elixir-lang.slack.com/archives/C03EPRA3B/p1716401796648339>)
Refactored CLI.State into CLI.History.
Added in some doctests and tidied up comments.

**Logs**

* 95f10b1 Hours of shit because of confusion about the name of the parent genserver (see: '<https://elixir-lang.slack.com/archives/C03EPRA3B/p1716401796648339>')
* 4a16a2b Hang onto pid of History genserver on start/2
* 64fce0f Hang onto pid of History genserver on start/2
* 6cf5187 Renamed all *Config to*Cfg for shorter module and function names
* f20a6de Renamed all *Config to*Cfg for shorter module and function names
* c79dcb2 Renamed all *Config to*Cfg for shorter module and function names
* ccd6ef9 Renamed DefaultConfigurator to DefaultConfig
* 21cec74 Working on CLI.Configurator to make Commands easier and simpler to specify
* 49dd394 Added tests to History to round out testing
* fdb0e84 Added tests to History to round out testing
* 36ab7d7 Refactrored Arca.CLI.State to History (because State is confusing)
* cfe4500 Tidied up some comments in Arca.State (prior to a refactor from Agent to GenServer)
* d15f442 Fixed start of Arca.CLI so that it shows usage when invoked with no command
* b808fa1 Tided up Utils.to_str and Utils.type_of
* ab0270c Updated deps for Arca.CLI.

##### 20240521

Did a bunch of tidying up on CLI, Repl, and Cfg to make things easier to use.

**Logs**

* be7bb0a  Fixed some output inconsistencies with get and about commands
* a28fc3c Updated docs
* 072fdf9 Updated docs
* d240bcb Updated docs
* 1b0816f Updated deps
* 3e320c5 Updated deps
* 995792a Updated deps
* 5260c74 Tidied up CLI and Repl _enourmously_ by fixing output and removing bad code
* f86018c Tidied up Cli to use function pattern matching for command dispatch
* 6b8de0b Refactored Arca.CLI and Arca.CLI.Test to work with new Cfg.
* e424025 Refactored Cfg to use get/put and get!/put! and then fixed the texts. Also updated deps.

##### 20240517

Having a crack at making the CLI a bit simpler to work with and extend by using behaviour.

**Logs**

* c40e893 Trying to build out behaviours that allow Commands to be standalone
* c2bb818 Moved about and repl into *Commands
* 0829482 Moved about and repl into *Commands
* f111aea Be more consistent with the use of Utils.* fns
* 31952b6 Starting to build out a behaviour-oriented command setup for CLI commands
* 2ec5a40 Moved Arca.CLI.History into its own directory
* 984f0de Refactored acra-cli to use arca-config as a separate package
* a0a90d6 Updated deps. Rebuilt. Refactoring Config, Cli, etc into separate arca-* projects

##### 20240502

Initial version

**Logs**

* 2193798 Ok, biting the bullet, I'm going to make arca-cli into an actual thing that I can then replace all of the *-clis in every other prj I'm working on
* d6eda31 Ok, biting the bullet, I'm going to make arca-cli into an actual thing that I can then replace all of the *-clis in every other prj I'm working on
