# Generic Python Toolbox

This toolbox is a WIP python port of the Advanced Bionics Generic Matlab Toolbox (GMT). The Generic Python Toolbox (GPyT) contains as series of functions used to emulate the current function of the HiRes 120 processing strategy. Documentation for the matlab model is included as the functions operate on identical inputs and outputs to their matlab counterparts. While the GMT supports an object orieted processing pipeline, the current implementation of GPyT is purely functional. 

# Dependencies
The GPyT relies on several key dependencies which are not included in this repository in order to run. All required depencies can currently be installed via PyPi using pip install <package name>. The full list of dependencies is included below.
 
NumPy - vector and matrix manipulations\
SciPy - signal processing and io functions\
PyAudio - audio playback package used only in the demo\
Numba - Just In Time compilation to optimize portions of vocoder simulation

# Demo
The GpyT includes a pre-configured demo 'demo3_procedural' which processes an audiofile containing 3 AzBio sentences in quiet. This demo can serve as a basic framework for developing novel processing pipelines. The demo returns a structure containing the results of each module in the processing pipeline and an audioOut vector generated using a tone vocoder. The output matrix is currently not saved to a file, but can be viewed/manipulated in the IDE after the demo has completed. 

 
