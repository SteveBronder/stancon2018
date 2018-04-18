The OpenCL methods to be presented at stancon 2018

To run these, download the following GPU branch and place it in a local folder

https://github.com/rok-cesnovar/math/tree/gpu_stanmathcl

In the `_Simulations/GP.R` file add at the top:

1. The location of your cmdstan directory
2. The location of the stan math GPU library

Then you should be able to run `GP.R` to produce the results, given that your computer has OpenCL and it's drivers properly installed.
