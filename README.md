SimulinkWrapper Proof of Concept
================================

Current state:
--------------
Each project contains 2 .m files. There is a build script that generates a .so file that MARTe will interface with. There is also a model, which gets imported into the build script - this is the part that I imagine third parties can edit. It contains just one function to define the behaviour of the controller. 

The IO of the build script must match the IO of the model function. At the moment this is filled in manually and therefore each model needs a matching build script. This can certainly be automated.

Future Vision:
--------------

- Automated MARTe code gen with EpicRT integration
- Automated build script to work out IO
- Parameters settable in the model without the need to rebuild the .so

Any questions, e-mail charles.boswell@ukaea.uk
