%GENERICJOINTTEST Test implementation of the generic joint class.
%
% About this main function:
% The main function collects all of the local test functions
% into a test array. Since it is the main function, the function name
% corresponds to the name of your .m file and follows the naming convention
% of starting or ending in the word 'test', which is case-insensitive.
%
% To run tests from the command prompt, use the runtests command with your
% MATLAB test file as input. For example:
%
%   results = runtests('genericJointTest.m')
%
% Alternatively, you can run tests using the run function.
%
%   results = run(genericJointTest)
%
% To analyze the test results, examine the output structure from runtests
% or run. For each test, the result contains the name of the test function,
% whether it passed, failed, or didn't complete, and the time it took to
% run the test.
%
% Author::
%  Joern Malzahn
%  Wesley Roozing
%
% See also genericJoint.

% Copyright (C) 2016, by Joern Malzahn, Wesley Roozing
%
% This file is part of the Compliant Joint Toolbox (CJT).
%
% CJT is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% CJT is distributed in the hope that it will be useful, but WITHOUT ANY
% WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
% License for more details.
%
% You should have received a copy of the GNU General Public License
% along with CJT. If not, see <http://www.gnu.org/licenses/>.
%
% For more information on the toolbox and contact to the authors visit
% <https://github.com/geez0x1/CompliantJointToolbox>

function [ tests ] = genericJointTest
    tests = functiontests(localfunctions);
end

% Setup and teardown code, also referred to as test fixture functions,
% set up the pretest state of the system and return it to the original
% state after running the test. There are two types of these functions:
% FILE FIXTURE functions that run once per test file, and FRESH FIXTURE
% functions that run before and after each local test function. These
% functions are not required to generate tests. In general, it is
% preferable to use fresh fixtures over file fixtures to increase unit test
% encapsulation.
%
% A function test case object, testCase, must be the only input to file
% fixture and fresh fixture functions. The Unit Test Framework
% automatically generates this object.
% The TestCase object is a means to pass information between setup
% functions, test functions, and teardown functions. Its TestData property
% is, by default, a struct, which allows easy addition of fields and data.
% Typical uses for this test data include paths and graphics handles.


% ----------------- FILE FIXTURE -----------------------
function setupOnce(testCase)  % do not change function name
% set a new path, for example

    % cleanup console
    close all;
    clc;

    % instantiate a joint builder
    testCase.('TestData').JB = jointBuilder;
    testCase.('TestData').JB.overwrite = 1; % Overwrite existing model files.
    
    parName = 'WMBig2300_ds';
    dynName = 'full_dyn';
    testCase.('TestData').className = ['WMBig2300_ds','_','full_dyn'];%     Instantiate a joint model

    % build a joint class for the test
    testCase.('TestData').JB.buildJoint(parName,...
        dynName);
    addpath(testCase.('TestData').JB.buildDir) % Add the built directory of the
    % joint builder to the search path.
    testCase.('TestData').testJoint = eval(testCase.('TestData').className);

end

function teardownOnce(testCase)  % do not change function name
% change back to original path, for example

    close all
    rmpath(testCase.('TestData').JB.buildDir); % Remove the built directory from the search path, then
    testCase.('TestData').JB.purge;            % remove all files created during the tests

end

% % ----------------- FRESH FIXTURE -----------------------
function setup(testCase)  % do not change function name
   % Instantiate a fresh joint object
   testCase.('TestData').testJoint = eval(testCase.('TestData').className);
end
%
% function teardown(testCase)  % do not change function name
% % close figure, for example
% end
% % -----------------------------------------------

% Individual test functions are included as local functions in the same
% MATLAB file as the main (test-generating) function. These test function
% names must begin or end with the case-insensitive word, 'test'. Each of
%the local test functions must accept a single input, which is a function
% test case object, testCase. The Unit Test Framework automatically
% generates this object.
%
% A test function is also called a "Qualification". There exist different
% conceptual types of qualifications.
function testBuiltJoint(testCase)
% Test specific code

    display('Name of the built joint under testing:')
    display(testCase.('TestData').testJoint.name);
    
    display('Name of the parameter set :')
    display(testCase.('TestData').testJoint.paramName);

end

function testConversionSymNum(testCase)
% Test specific code

   
    % This test requires the symbolic math toolbox. Only run it, if it is there.
    v = ver;
    has_Symbolic_Toolbox = any(strcmp('Symbolic Math Toolbox', {v.Name}));
    assumeTrue(testCase, has_Symbolic_Toolbox  );
    
    % Conversion to symboic
    display('Converting joint parameter to symbolic')
    testCase.('TestData').testJoint.makeSym;
    
    isSym = testCase.('TestData').testJoint.isSym;
    
    % Conversion back to numeric
    display('Converting joint parameter to symbolic')
    testCase.('TestData').testJoint.makeNum;
    
    isNum = 1 - testCase.('TestData').testJoint.isSym;
    
    % Verify test
    verifyEqual(testCase, isSym, 1 );
    verifyEqual(testCase, isNum, 1 );
    
    
end

function testSymbolicStateSpace(testCase)
% Test specific code
   
    % This test requires the symbolic math toolbox. Only run it, if it is there.
    v = ver;
    has_Symbolic_Toolbox = any(strcmp('Symbolic Math Toolbox', {v.Name}));
    assumeTrue(testCase, has_Symbolic_Toolbox  );
    
    % Conversion to symboic
    display('Converting joint parameter to symbolic')
    testCase.('TestData').testJoint.makeSym;
    
    % Compute symbolic linear dynamics matrices
    [A, B, C, D, I, R, K] = testCase.('TestData').testJoint.getDynamicsMatrices;
    
   
    syms I_l Im_g Im_m d_l dm_g d_gl dm_m dm_mg k_b k_g k_t n
    Anom = ...
    [               0,                       0,              0,                    1,                                         0,                 0;
                    0,                       0,              0,                    0,                                         1,                 0;
                    0,                       0,              0,                    0,                                         0,                 1;
      -k_g/(Im_m*n^2),          k_g/(Im_m*n^2),              0, -(dm_m + dm_mg)/Im_m,                                dm_mg/Im_m,                 0;
       k_g/(Im_g*n^2), -(k_b + k_g)/(Im_g*n^2), k_b/(Im_g*n^2),           dm_mg/Im_g, -(d_gl + dm_g*n^2 + dm_mg*n^2)/(Im_g*n^2),   d_gl/(Im_g*n^2);
                    0,                 k_b/I_l,       -k_b/I_l,                    0,                                  d_gl/I_l, -(d_gl + d_l)/I_l];
 
         
    Bnom = ...
    [            0,     0;
                 0,     0;
                 0,     0;
      k_t/(Im_m*n),     0;
                 0,     0;
                 0, 1/I_l];
               
    Cnom = ...
    [ 1,   0,    0, 0,    0,     0;
      0,   1,    0, 0,    0,     0;
      0,   0,    1, 0,    0,     0;
      0,   0,    0, 1,    0,     0;
      0,   0,    0, 0,    1,     0;
      0,   0,    0, 0,    0,     1;
      0, k_b, -k_b, 0, d_gl, -d_gl];
  
    Dnom = [ 0, 0;
             0, 0;
             0, 0;
             0, 0;
             0, 0;
             0, 0;
             0, 0];
    
    Inom = ...
    [ Im_m*n^2,        0,   0;
             0, Im_g*n^2,   0;
             0,        0, I_l];

    Rnom = ...
    [ dm_m*n^2 + dm_mg*n^2,                  -dm_mg*n^2,          0;
                -dm_mg*n^2, d_gl + dm_g*n^2 + dm_mg*n^2,      -d_gl;
                         0,                       -d_gl, d_gl + d_l];


    Knom = ...
    [  k_g,      -k_g,    0;
      -k_g, k_b + k_g, -k_b;
         0,      -k_b,  k_b];
 
    verifyEqual(testCase,A,Anom);
    verifyEqual(testCase,B,Bnom);
    verifyEqual(testCase,C,Cnom);
    verifyEqual(testCase,D,Dnom);
    verifyEqual(testCase,I,Inom);
    verifyEqual(testCase,R,Rnom);
    verifyEqual(testCase,K,Knom);

end


function testSymbolicTransferFunction(testCase)
% Test specific code
   
    % This test requires the symbolic math toolbox. Only run it, if it is there.
    v = ver;
    has_Symbolic_Toolbox = any(strcmp('Symbolic Math Toolbox', {v.Name}));
    assumeTrue(testCase, has_Symbolic_Toolbox  );
    
    % Conversion to symboic
    display('Converting joint parameter to symbolic')
    testCase.('TestData').testJoint.makeSym;
    
    % Compute symbolic linear transfer function
    TFSym = testCase.('TestData').testJoint.getTF;
    
    % The transfer function should only include these variables
    syms I_l Im_g Im_m d_l dm_g d_gl dm_m dm_mg k_b k_g k_t n s
    
    % The transfer function should have this form
    TFNom = ...
    [ (k_t*n*(k_b*k_g + d_l*k_b*s + d_gl*k_g*s + d_l*k_g*s + I_l*d_gl*s^3 + I_l*k_b*s^2 + I_l*k_g*s^2 + d_gl*d_l*s^2 + dm_g*k_b*n^2*s + dm_mg*k_b*n^2*s + I_l*Im_g*n^2*s^4 + Im_g*d_gl*n^2*s^3 + I_l*dm_g*n^2*s^3 + Im_g*d_l*n^2*s^3 + I_l*dm_mg*n^2*s^3 + Im_g*k_b*n^2*s^2 + d_gl*dm_g*n^2*s^2 + d_gl*dm_mg*n^2*s^2 + d_l*dm_g*n^2*s^2 + d_l*dm_mg*n^2*s^2))/(d_l*k_b*k_g*s + I_l*d_gl*k_g*s^3 + I_l*k_b*k_g*s^2 + d_gl*d_l*k_g*s^2 + I_l*d_gl*dm_m*n^2*s^4 + Im_m*d_gl*d_l*n^2*s^4 + I_l*d_gl*dm_mg*n^2*s^4 + Im_g*d_gl*dm_m*n^4*s^4 + Im_m*d_gl*dm_g*n^4*s^4 + Im_g*d_gl*dm_mg*n^4*s^4 + Im_m*d_gl*dm_mg*n^4*s^4 + I_l*dm_g*dm_m*n^4*s^4 + Im_g*d_l*dm_m*n^4*s^4 + Im_m*d_l*dm_g*n^4*s^4 + I_l*dm_g*dm_mg*n^4*s^4 + Im_g*d_l*dm_mg*n^4*s^4 + I_l*dm_m*dm_mg*n^4*s^4 + Im_m*d_l*dm_mg*n^4*s^4 + I_l*dm_m*k_b*n^2*s^3 + Im_m*d_l*k_b*n^2*s^3 + Im_g*d_gl*k_g*n^2*s^3 + I_l*dm_mg*k_b*n^2*s^3 + Im_m*d_gl*k_g*n^2*s^3 + I_l*dm_g*k_g*n^2*s^3 + Im_g*d_l*k_g*n^2*s^3 + I_l*dm_m*k_g*n^2*s^3 + Im_m*d_l*k_g*n^2*s^3 + Im_g*dm_m*k_b*n^4*s^3 + Im_m*dm_g*k_b*n^4*s^3 + Im_g*dm_mg*k_b*n^4*s^3 + Im_m*dm_mg*k_b*n^4*s^3 + Im_g*k_b*k_g*n^2*s^2 + Im_m*k_b*k_g*n^2*s^2 + d_gl*d_l*dm_m*n^2*s^3 + d_gl*d_l*dm_mg*n^2*s^3 + d_gl*dm_g*dm_m*n^4*s^3 + d_gl*dm_g*dm_mg*n^4*s^3 + d_gl*dm_m*dm_mg*n^4*s^3 + d_l*dm_g*dm_m*n^4*s^3 + d_l*dm_g*dm_mg*n^4*s^3 + d_l*dm_m*dm_mg*n^4*s^3 + d_l*dm_m*k_b*n^2*s^2 + d_gl*dm_g*k_g*n^2*s^2 + d_l*dm_mg*k_b*n^2*s^2 + d_gl*dm_m*k_g*n^2*s^2 + d_l*dm_g*k_g*n^2*s^2 + d_l*dm_m*k_g*n^2*s^2 + dm_g*dm_m*k_b*n^4*s^2 + dm_g*dm_mg*k_b*n^4*s^2 + dm_m*dm_mg*k_b*n^4*s^2 + dm_g*k_b*k_g*n^2*s + dm_m*k_b*k_g*n^2*s + I_l*Im_g*Im_m*n^4*s^6 + I_l*Im_m*d_gl*n^2*s^5 + Im_g*Im_m*d_gl*n^4*s^5 + I_l*Im_g*dm_m*n^4*s^5 + I_l*Im_m*dm_g*n^4*s^5 + Im_g*Im_m*d_l*n^4*s^5 + I_l*Im_g*dm_mg*n^4*s^5 + I_l*Im_m*dm_mg*n^4*s^5 + I_l*Im_m*k_b*n^2*s^4 + I_l*Im_g*k_g*n^2*s^4 + I_l*Im_m*k_g*n^2*s^4 + Im_g*Im_m*k_b*n^4*s^4),                                                                                                                                                                                                                                                                                                                                                  ((k_b + d_gl*s)*(dm_mg*s*n^2 + k_g))/(d_l*k_b*k_g*s + I_l*d_gl*k_g*s^3 + I_l*k_b*k_g*s^2 + d_gl*d_l*k_g*s^2 + I_l*d_gl*dm_m*n^2*s^4 + Im_m*d_gl*d_l*n^2*s^4 + I_l*d_gl*dm_mg*n^2*s^4 + Im_g*d_gl*dm_m*n^4*s^4 + Im_m*d_gl*dm_g*n^4*s^4 + Im_g*d_gl*dm_mg*n^4*s^4 + Im_m*d_gl*dm_mg*n^4*s^4 + I_l*dm_g*dm_m*n^4*s^4 + Im_g*d_l*dm_m*n^4*s^4 + Im_m*d_l*dm_g*n^4*s^4 + I_l*dm_g*dm_mg*n^4*s^4 + Im_g*d_l*dm_mg*n^4*s^4 + I_l*dm_m*dm_mg*n^4*s^4 + Im_m*d_l*dm_mg*n^4*s^4 + I_l*dm_m*k_b*n^2*s^3 + Im_m*d_l*k_b*n^2*s^3 + Im_g*d_gl*k_g*n^2*s^3 + I_l*dm_mg*k_b*n^2*s^3 + Im_m*d_gl*k_g*n^2*s^3 + I_l*dm_g*k_g*n^2*s^3 + Im_g*d_l*k_g*n^2*s^3 + I_l*dm_m*k_g*n^2*s^3 + Im_m*d_l*k_g*n^2*s^3 + Im_g*dm_m*k_b*n^4*s^3 + Im_m*dm_g*k_b*n^4*s^3 + Im_g*dm_mg*k_b*n^4*s^3 + Im_m*dm_mg*k_b*n^4*s^3 + Im_g*k_b*k_g*n^2*s^2 + Im_m*k_b*k_g*n^2*s^2 + d_gl*d_l*dm_m*n^2*s^3 + d_gl*d_l*dm_mg*n^2*s^3 + d_gl*dm_g*dm_m*n^4*s^3 + d_gl*dm_g*dm_mg*n^4*s^3 + d_gl*dm_m*dm_mg*n^4*s^3 + d_l*dm_g*dm_m*n^4*s^3 + d_l*dm_g*dm_mg*n^4*s^3 + d_l*dm_m*dm_mg*n^4*s^3 + d_l*dm_m*k_b*n^2*s^2 + d_gl*dm_g*k_g*n^2*s^2 + d_l*dm_mg*k_b*n^2*s^2 + d_gl*dm_m*k_g*n^2*s^2 + d_l*dm_g*k_g*n^2*s^2 + d_l*dm_m*k_g*n^2*s^2 + dm_g*dm_m*k_b*n^4*s^2 + dm_g*dm_mg*k_b*n^4*s^2 + dm_m*dm_mg*k_b*n^4*s^2 + dm_g*k_b*k_g*n^2*s + dm_m*k_b*k_g*n^2*s + I_l*Im_g*Im_m*n^4*s^6 + I_l*Im_m*d_gl*n^2*s^5 + Im_g*Im_m*d_gl*n^4*s^5 + I_l*Im_g*dm_m*n^4*s^5 + I_l*Im_m*dm_g*n^4*s^5 + Im_g*Im_m*d_l*n^4*s^5 + I_l*Im_g*dm_mg*n^4*s^5 + I_l*Im_m*dm_mg*n^4*s^5 + I_l*Im_m*k_b*n^2*s^4 + I_l*Im_g*k_g*n^2*s^4 + I_l*Im_m*k_g*n^2*s^4 + Im_g*Im_m*k_b*n^4*s^4);
                                                                                                                                                                                                                                                                                                 (k_t*n*(dm_mg*s*n^2 + k_g)*(k_b + d_gl*s + d_l*s + I_l*s^2))/(d_l*k_b*k_g*s + I_l*d_gl*k_g*s^3 + I_l*k_b*k_g*s^2 + d_gl*d_l*k_g*s^2 + I_l*d_gl*dm_m*n^2*s^4 + Im_m*d_gl*d_l*n^2*s^4 + I_l*d_gl*dm_mg*n^2*s^4 + Im_g*d_gl*dm_m*n^4*s^4 + Im_m*d_gl*dm_g*n^4*s^4 + Im_g*d_gl*dm_mg*n^4*s^4 + Im_m*d_gl*dm_mg*n^4*s^4 + I_l*dm_g*dm_m*n^4*s^4 + Im_g*d_l*dm_m*n^4*s^4 + Im_m*d_l*dm_g*n^4*s^4 + I_l*dm_g*dm_mg*n^4*s^4 + Im_g*d_l*dm_mg*n^4*s^4 + I_l*dm_m*dm_mg*n^4*s^4 + Im_m*d_l*dm_mg*n^4*s^4 + I_l*dm_m*k_b*n^2*s^3 + Im_m*d_l*k_b*n^2*s^3 + Im_g*d_gl*k_g*n^2*s^3 + I_l*dm_mg*k_b*n^2*s^3 + Im_m*d_gl*k_g*n^2*s^3 + I_l*dm_g*k_g*n^2*s^3 + Im_g*d_l*k_g*n^2*s^3 + I_l*dm_m*k_g*n^2*s^3 + Im_m*d_l*k_g*n^2*s^3 + Im_g*dm_m*k_b*n^4*s^3 + Im_m*dm_g*k_b*n^4*s^3 + Im_g*dm_mg*k_b*n^4*s^3 + Im_m*dm_mg*k_b*n^4*s^3 + Im_g*k_b*k_g*n^2*s^2 + Im_m*k_b*k_g*n^2*s^2 + d_gl*d_l*dm_m*n^2*s^3 + d_gl*d_l*dm_mg*n^2*s^3 + d_gl*dm_g*dm_m*n^4*s^3 + d_gl*dm_g*dm_mg*n^4*s^3 + d_gl*dm_m*dm_mg*n^4*s^3 + d_l*dm_g*dm_m*n^4*s^3 + d_l*dm_g*dm_mg*n^4*s^3 + d_l*dm_m*dm_mg*n^4*s^3 + d_l*dm_m*k_b*n^2*s^2 + d_gl*dm_g*k_g*n^2*s^2 + d_l*dm_mg*k_b*n^2*s^2 + d_gl*dm_m*k_g*n^2*s^2 + d_l*dm_g*k_g*n^2*s^2 + d_l*dm_m*k_g*n^2*s^2 + dm_g*dm_m*k_b*n^4*s^2 + dm_g*dm_mg*k_b*n^4*s^2 + dm_m*dm_mg*k_b*n^4*s^2 + dm_g*k_b*k_g*n^2*s + dm_m*k_b*k_g*n^2*s + I_l*Im_g*Im_m*n^4*s^6 + I_l*Im_m*d_gl*n^2*s^5 + Im_g*Im_m*d_gl*n^4*s^5 + I_l*Im_g*dm_m*n^4*s^5 + I_l*Im_m*dm_g*n^4*s^5 + Im_g*Im_m*d_l*n^4*s^5 + I_l*Im_g*dm_mg*n^4*s^5 + I_l*Im_m*dm_mg*n^4*s^5 + I_l*Im_m*k_b*n^2*s^4 + I_l*Im_g*k_g*n^2*s^4 + I_l*Im_m*k_g*n^2*s^4 + Im_g*Im_m*k_b*n^4*s^4),                                                                                                                                                                                                                                                                                                                      ((k_b + d_gl*s)*(k_g + dm_m*n^2*s + dm_mg*n^2*s + Im_m*n^2*s^2))/(d_l*k_b*k_g*s + I_l*d_gl*k_g*s^3 + I_l*k_b*k_g*s^2 + d_gl*d_l*k_g*s^2 + I_l*d_gl*dm_m*n^2*s^4 + Im_m*d_gl*d_l*n^2*s^4 + I_l*d_gl*dm_mg*n^2*s^4 + Im_g*d_gl*dm_m*n^4*s^4 + Im_m*d_gl*dm_g*n^4*s^4 + Im_g*d_gl*dm_mg*n^4*s^4 + Im_m*d_gl*dm_mg*n^4*s^4 + I_l*dm_g*dm_m*n^4*s^4 + Im_g*d_l*dm_m*n^4*s^4 + Im_m*d_l*dm_g*n^4*s^4 + I_l*dm_g*dm_mg*n^4*s^4 + Im_g*d_l*dm_mg*n^4*s^4 + I_l*dm_m*dm_mg*n^4*s^4 + Im_m*d_l*dm_mg*n^4*s^4 + I_l*dm_m*k_b*n^2*s^3 + Im_m*d_l*k_b*n^2*s^3 + Im_g*d_gl*k_g*n^2*s^3 + I_l*dm_mg*k_b*n^2*s^3 + Im_m*d_gl*k_g*n^2*s^3 + I_l*dm_g*k_g*n^2*s^3 + Im_g*d_l*k_g*n^2*s^3 + I_l*dm_m*k_g*n^2*s^3 + Im_m*d_l*k_g*n^2*s^3 + Im_g*dm_m*k_b*n^4*s^3 + Im_m*dm_g*k_b*n^4*s^3 + Im_g*dm_mg*k_b*n^4*s^3 + Im_m*dm_mg*k_b*n^4*s^3 + Im_g*k_b*k_g*n^2*s^2 + Im_m*k_b*k_g*n^2*s^2 + d_gl*d_l*dm_m*n^2*s^3 + d_gl*d_l*dm_mg*n^2*s^3 + d_gl*dm_g*dm_m*n^4*s^3 + d_gl*dm_g*dm_mg*n^4*s^3 + d_gl*dm_m*dm_mg*n^4*s^3 + d_l*dm_g*dm_m*n^4*s^3 + d_l*dm_g*dm_mg*n^4*s^3 + d_l*dm_m*dm_mg*n^4*s^3 + d_l*dm_m*k_b*n^2*s^2 + d_gl*dm_g*k_g*n^2*s^2 + d_l*dm_mg*k_b*n^2*s^2 + d_gl*dm_m*k_g*n^2*s^2 + d_l*dm_g*k_g*n^2*s^2 + d_l*dm_m*k_g*n^2*s^2 + dm_g*dm_m*k_b*n^4*s^2 + dm_g*dm_mg*k_b*n^4*s^2 + dm_m*dm_mg*k_b*n^4*s^2 + dm_g*k_b*k_g*n^2*s + dm_m*k_b*k_g*n^2*s + I_l*Im_g*Im_m*n^4*s^6 + I_l*Im_m*d_gl*n^2*s^5 + Im_g*Im_m*d_gl*n^4*s^5 + I_l*Im_g*dm_m*n^4*s^5 + I_l*Im_m*dm_g*n^4*s^5 + Im_g*Im_m*d_l*n^4*s^5 + I_l*Im_g*dm_mg*n^4*s^5 + I_l*Im_m*dm_mg*n^4*s^5 + I_l*Im_m*k_b*n^2*s^4 + I_l*Im_g*k_g*n^2*s^4 + I_l*Im_m*k_g*n^2*s^4 + Im_g*Im_m*k_b*n^4*s^4);
                                                                                                                                                                                                                                                                                                                   (k_t*n*(k_b + d_gl*s)*(dm_mg*s*n^2 + k_g))/(d_l*k_b*k_g*s + I_l*d_gl*k_g*s^3 + I_l*k_b*k_g*s^2 + d_gl*d_l*k_g*s^2 + I_l*d_gl*dm_m*n^2*s^4 + Im_m*d_gl*d_l*n^2*s^4 + I_l*d_gl*dm_mg*n^2*s^4 + Im_g*d_gl*dm_m*n^4*s^4 + Im_m*d_gl*dm_g*n^4*s^4 + Im_g*d_gl*dm_mg*n^4*s^4 + Im_m*d_gl*dm_mg*n^4*s^4 + I_l*dm_g*dm_m*n^4*s^4 + Im_g*d_l*dm_m*n^4*s^4 + Im_m*d_l*dm_g*n^4*s^4 + I_l*dm_g*dm_mg*n^4*s^4 + Im_g*d_l*dm_mg*n^4*s^4 + I_l*dm_m*dm_mg*n^4*s^4 + Im_m*d_l*dm_mg*n^4*s^4 + I_l*dm_m*k_b*n^2*s^3 + Im_m*d_l*k_b*n^2*s^3 + Im_g*d_gl*k_g*n^2*s^3 + I_l*dm_mg*k_b*n^2*s^3 + Im_m*d_gl*k_g*n^2*s^3 + I_l*dm_g*k_g*n^2*s^3 + Im_g*d_l*k_g*n^2*s^3 + I_l*dm_m*k_g*n^2*s^3 + Im_m*d_l*k_g*n^2*s^3 + Im_g*dm_m*k_b*n^4*s^3 + Im_m*dm_g*k_b*n^4*s^3 + Im_g*dm_mg*k_b*n^4*s^3 + Im_m*dm_mg*k_b*n^4*s^3 + Im_g*k_b*k_g*n^2*s^2 + Im_m*k_b*k_g*n^2*s^2 + d_gl*d_l*dm_m*n^2*s^3 + d_gl*d_l*dm_mg*n^2*s^3 + d_gl*dm_g*dm_m*n^4*s^3 + d_gl*dm_g*dm_mg*n^4*s^3 + d_gl*dm_m*dm_mg*n^4*s^3 + d_l*dm_g*dm_m*n^4*s^3 + d_l*dm_g*dm_mg*n^4*s^3 + d_l*dm_m*dm_mg*n^4*s^3 + d_l*dm_m*k_b*n^2*s^2 + d_gl*dm_g*k_g*n^2*s^2 + d_l*dm_mg*k_b*n^2*s^2 + d_gl*dm_m*k_g*n^2*s^2 + d_l*dm_g*k_g*n^2*s^2 + d_l*dm_m*k_g*n^2*s^2 + dm_g*dm_m*k_b*n^4*s^2 + dm_g*dm_mg*k_b*n^4*s^2 + dm_m*dm_mg*k_b*n^4*s^2 + dm_g*k_b*k_g*n^2*s + dm_m*k_b*k_g*n^2*s + I_l*Im_g*Im_m*n^4*s^6 + I_l*Im_m*d_gl*n^2*s^5 + Im_g*Im_m*d_gl*n^4*s^5 + I_l*Im_g*dm_m*n^4*s^5 + I_l*Im_m*dm_g*n^4*s^5 + Im_g*Im_m*d_l*n^4*s^5 + I_l*Im_g*dm_mg*n^4*s^5 + I_l*Im_m*dm_mg*n^4*s^5 + I_l*Im_m*k_b*n^2*s^4 + I_l*Im_g*k_g*n^2*s^4 + I_l*Im_m*k_g*n^2*s^4 + Im_g*Im_m*k_b*n^4*s^4), (k_b*k_g + d_gl*k_g*s + dm_m*k_b*n^2*s + dm_mg*k_b*n^2*s + dm_g*k_g*n^2*s + dm_m*k_g*n^2*s + Im_g*Im_m*n^4*s^4 + Im_m*d_gl*n^2*s^3 + Im_g*dm_m*n^4*s^3 + Im_m*dm_g*n^4*s^3 + Im_g*dm_mg*n^4*s^3 + Im_m*dm_mg*n^4*s^3 + Im_m*k_b*n^2*s^2 + Im_g*k_g*n^2*s^2 + Im_m*k_g*n^2*s^2 + d_gl*dm_m*n^2*s^2 + d_gl*dm_mg*n^2*s^2 + dm_g*dm_m*n^4*s^2 + dm_g*dm_mg*n^4*s^2 + dm_m*dm_mg*n^4*s^2)/(d_l*k_b*k_g*s + I_l*d_gl*k_g*s^3 + I_l*k_b*k_g*s^2 + d_gl*d_l*k_g*s^2 + I_l*d_gl*dm_m*n^2*s^4 + Im_m*d_gl*d_l*n^2*s^4 + I_l*d_gl*dm_mg*n^2*s^4 + Im_g*d_gl*dm_m*n^4*s^4 + Im_m*d_gl*dm_g*n^4*s^4 + Im_g*d_gl*dm_mg*n^4*s^4 + Im_m*d_gl*dm_mg*n^4*s^4 + I_l*dm_g*dm_m*n^4*s^4 + Im_g*d_l*dm_m*n^4*s^4 + Im_m*d_l*dm_g*n^4*s^4 + I_l*dm_g*dm_mg*n^4*s^4 + Im_g*d_l*dm_mg*n^4*s^4 + I_l*dm_m*dm_mg*n^4*s^4 + Im_m*d_l*dm_mg*n^4*s^4 + I_l*dm_m*k_b*n^2*s^3 + Im_m*d_l*k_b*n^2*s^3 + Im_g*d_gl*k_g*n^2*s^3 + I_l*dm_mg*k_b*n^2*s^3 + Im_m*d_gl*k_g*n^2*s^3 + I_l*dm_g*k_g*n^2*s^3 + Im_g*d_l*k_g*n^2*s^3 + I_l*dm_m*k_g*n^2*s^3 + Im_m*d_l*k_g*n^2*s^3 + Im_g*dm_m*k_b*n^4*s^3 + Im_m*dm_g*k_b*n^4*s^3 + Im_g*dm_mg*k_b*n^4*s^3 + Im_m*dm_mg*k_b*n^4*s^3 + Im_g*k_b*k_g*n^2*s^2 + Im_m*k_b*k_g*n^2*s^2 + d_gl*d_l*dm_m*n^2*s^3 + d_gl*d_l*dm_mg*n^2*s^3 + d_gl*dm_g*dm_m*n^4*s^3 + d_gl*dm_g*dm_mg*n^4*s^3 + d_gl*dm_m*dm_mg*n^4*s^3 + d_l*dm_g*dm_m*n^4*s^3 + d_l*dm_g*dm_mg*n^4*s^3 + d_l*dm_m*dm_mg*n^4*s^3 + d_l*dm_m*k_b*n^2*s^2 + d_gl*dm_g*k_g*n^2*s^2 + d_l*dm_mg*k_b*n^2*s^2 + d_gl*dm_m*k_g*n^2*s^2 + d_l*dm_g*k_g*n^2*s^2 + d_l*dm_m*k_g*n^2*s^2 + dm_g*dm_m*k_b*n^4*s^2 + dm_g*dm_mg*k_b*n^4*s^2 + dm_m*dm_mg*k_b*n^4*s^2 + dm_g*k_b*k_g*n^2*s + dm_m*k_b*k_g*n^2*s + I_l*Im_g*Im_m*n^4*s^6 + I_l*Im_m*d_gl*n^2*s^5 + Im_g*Im_m*d_gl*n^4*s^5 + I_l*Im_g*dm_m*n^4*s^5 + I_l*Im_m*dm_g*n^4*s^5 + Im_g*Im_m*d_l*n^4*s^5 + I_l*Im_g*dm_mg*n^4*s^5 + I_l*Im_m*dm_mg*n^4*s^5 + I_l*Im_m*k_b*n^2*s^4 + I_l*Im_g*k_g*n^2*s^4 + I_l*Im_m*k_g*n^2*s^4 + Im_g*Im_m*k_b*n^4*s^4);
                                      (k_t*n*(k_b*k_g + d_l*k_b*s + d_gl*k_g*s + d_l*k_g*s + I_l*d_gl*s^3 + I_l*k_b*s^2 + I_l*k_g*s^2 + d_gl*d_l*s^2 + dm_g*k_b*n^2*s + dm_mg*k_b*n^2*s + I_l*Im_g*n^2*s^4 + Im_g*d_gl*n^2*s^3 + I_l*dm_g*n^2*s^3 + Im_g*d_l*n^2*s^3 + I_l*dm_mg*n^2*s^3 + Im_g*k_b*n^2*s^2 + d_gl*dm_g*n^2*s^2 + d_gl*dm_mg*n^2*s^2 + d_l*dm_g*n^2*s^2 + d_l*dm_mg*n^2*s^2))/(d_l*k_b*k_g + d_gl*d_l*k_g*s + I_l*d_gl*k_g*s^2 + dm_g*k_b*k_g*n^2 + dm_m*k_b*k_g*n^2 + I_l*k_b*k_g*s + I_l*d_gl*dm_m*n^2*s^3 + Im_m*d_gl*d_l*n^2*s^3 + I_l*d_gl*dm_mg*n^2*s^3 + Im_g*d_gl*dm_m*n^4*s^3 + Im_m*d_gl*dm_g*n^4*s^3 + Im_g*d_gl*dm_mg*n^4*s^3 + Im_m*d_gl*dm_mg*n^4*s^3 + I_l*dm_g*dm_m*n^4*s^3 + Im_g*d_l*dm_m*n^4*s^3 + Im_m*d_l*dm_g*n^4*s^3 + I_l*dm_g*dm_mg*n^4*s^3 + Im_g*d_l*dm_mg*n^4*s^3 + I_l*dm_m*dm_mg*n^4*s^3 + Im_m*d_l*dm_mg*n^4*s^3 + I_l*dm_m*k_b*n^2*s^2 + Im_m*d_l*k_b*n^2*s^2 + Im_g*d_gl*k_g*n^2*s^2 + I_l*dm_mg*k_b*n^2*s^2 + Im_m*d_gl*k_g*n^2*s^2 + I_l*dm_g*k_g*n^2*s^2 + Im_g*d_l*k_g*n^2*s^2 + I_l*dm_m*k_g*n^2*s^2 + Im_m*d_l*k_g*n^2*s^2 + Im_g*dm_m*k_b*n^4*s^2 + Im_m*dm_g*k_b*n^4*s^2 + Im_g*dm_mg*k_b*n^4*s^2 + Im_m*dm_mg*k_b*n^4*s^2 + d_gl*d_l*dm_m*n^2*s^2 + d_gl*d_l*dm_mg*n^2*s^2 + d_gl*dm_g*dm_m*n^4*s^2 + d_gl*dm_g*dm_mg*n^4*s^2 + d_gl*dm_m*dm_mg*n^4*s^2 + d_l*dm_g*dm_m*n^4*s^2 + d_l*dm_g*dm_mg*n^4*s^2 + d_l*dm_m*dm_mg*n^4*s^2 + Im_g*k_b*k_g*n^2*s + Im_m*k_b*k_g*n^2*s + d_l*dm_m*k_b*n^2*s + d_gl*dm_g*k_g*n^2*s + d_l*dm_mg*k_b*n^2*s + d_gl*dm_m*k_g*n^2*s + d_l*dm_g*k_g*n^2*s + d_l*dm_m*k_g*n^2*s + dm_g*dm_m*k_b*n^4*s + dm_g*dm_mg*k_b*n^4*s + dm_m*dm_mg*k_b*n^4*s + I_l*Im_g*Im_m*n^4*s^5 + I_l*Im_m*d_gl*n^2*s^4 + Im_g*Im_m*d_gl*n^4*s^4 + I_l*Im_g*dm_m*n^4*s^4 + I_l*Im_m*dm_g*n^4*s^4 + Im_g*Im_m*d_l*n^4*s^4 + I_l*Im_g*dm_mg*n^4*s^4 + I_l*Im_m*dm_mg*n^4*s^4 + I_l*Im_m*k_b*n^2*s^3 + I_l*Im_g*k_g*n^2*s^3 + I_l*Im_m*k_g*n^2*s^3 + Im_g*Im_m*k_b*n^4*s^3),                                                                                                                                                                                                                                                                                                                                                                                  ((k_b + d_gl*s)*(dm_mg*s*n^2 + k_g))/(d_l*k_b*k_g + d_gl*d_l*k_g*s + I_l*d_gl*k_g*s^2 + dm_g*k_b*k_g*n^2 + dm_m*k_b*k_g*n^2 + I_l*k_b*k_g*s + I_l*d_gl*dm_m*n^2*s^3 + Im_m*d_gl*d_l*n^2*s^3 + I_l*d_gl*dm_mg*n^2*s^3 + Im_g*d_gl*dm_m*n^4*s^3 + Im_m*d_gl*dm_g*n^4*s^3 + Im_g*d_gl*dm_mg*n^4*s^3 + Im_m*d_gl*dm_mg*n^4*s^3 + I_l*dm_g*dm_m*n^4*s^3 + Im_g*d_l*dm_m*n^4*s^3 + Im_m*d_l*dm_g*n^4*s^3 + I_l*dm_g*dm_mg*n^4*s^3 + Im_g*d_l*dm_mg*n^4*s^3 + I_l*dm_m*dm_mg*n^4*s^3 + Im_m*d_l*dm_mg*n^4*s^3 + I_l*dm_m*k_b*n^2*s^2 + Im_m*d_l*k_b*n^2*s^2 + Im_g*d_gl*k_g*n^2*s^2 + I_l*dm_mg*k_b*n^2*s^2 + Im_m*d_gl*k_g*n^2*s^2 + I_l*dm_g*k_g*n^2*s^2 + Im_g*d_l*k_g*n^2*s^2 + I_l*dm_m*k_g*n^2*s^2 + Im_m*d_l*k_g*n^2*s^2 + Im_g*dm_m*k_b*n^4*s^2 + Im_m*dm_g*k_b*n^4*s^2 + Im_g*dm_mg*k_b*n^4*s^2 + Im_m*dm_mg*k_b*n^4*s^2 + d_gl*d_l*dm_m*n^2*s^2 + d_gl*d_l*dm_mg*n^2*s^2 + d_gl*dm_g*dm_m*n^4*s^2 + d_gl*dm_g*dm_mg*n^4*s^2 + d_gl*dm_m*dm_mg*n^4*s^2 + d_l*dm_g*dm_m*n^4*s^2 + d_l*dm_g*dm_mg*n^4*s^2 + d_l*dm_m*dm_mg*n^4*s^2 + Im_g*k_b*k_g*n^2*s + Im_m*k_b*k_g*n^2*s + d_l*dm_m*k_b*n^2*s + d_gl*dm_g*k_g*n^2*s + d_l*dm_mg*k_b*n^2*s + d_gl*dm_m*k_g*n^2*s + d_l*dm_g*k_g*n^2*s + d_l*dm_m*k_g*n^2*s + dm_g*dm_m*k_b*n^4*s + dm_g*dm_mg*k_b*n^4*s + dm_m*dm_mg*k_b*n^4*s + I_l*Im_g*Im_m*n^4*s^5 + I_l*Im_m*d_gl*n^2*s^4 + Im_g*Im_m*d_gl*n^4*s^4 + I_l*Im_g*dm_m*n^4*s^4 + I_l*Im_m*dm_g*n^4*s^4 + Im_g*Im_m*d_l*n^4*s^4 + I_l*Im_g*dm_mg*n^4*s^4 + I_l*Im_m*dm_mg*n^4*s^4 + I_l*Im_m*k_b*n^2*s^3 + I_l*Im_g*k_g*n^2*s^3 + I_l*Im_m*k_g*n^2*s^3 + Im_g*Im_m*k_b*n^4*s^3);
                                                                                                                                                                                                                                                                                                                                 (k_t*n*(dm_mg*s*n^2 + k_g)*(k_b + d_gl*s + d_l*s + I_l*s^2))/(d_l*k_b*k_g + d_gl*d_l*k_g*s + I_l*d_gl*k_g*s^2 + dm_g*k_b*k_g*n^2 + dm_m*k_b*k_g*n^2 + I_l*k_b*k_g*s + I_l*d_gl*dm_m*n^2*s^3 + Im_m*d_gl*d_l*n^2*s^3 + I_l*d_gl*dm_mg*n^2*s^3 + Im_g*d_gl*dm_m*n^4*s^3 + Im_m*d_gl*dm_g*n^4*s^3 + Im_g*d_gl*dm_mg*n^4*s^3 + Im_m*d_gl*dm_mg*n^4*s^3 + I_l*dm_g*dm_m*n^4*s^3 + Im_g*d_l*dm_m*n^4*s^3 + Im_m*d_l*dm_g*n^4*s^3 + I_l*dm_g*dm_mg*n^4*s^3 + Im_g*d_l*dm_mg*n^4*s^3 + I_l*dm_m*dm_mg*n^4*s^3 + Im_m*d_l*dm_mg*n^4*s^3 + I_l*dm_m*k_b*n^2*s^2 + Im_m*d_l*k_b*n^2*s^2 + Im_g*d_gl*k_g*n^2*s^2 + I_l*dm_mg*k_b*n^2*s^2 + Im_m*d_gl*k_g*n^2*s^2 + I_l*dm_g*k_g*n^2*s^2 + Im_g*d_l*k_g*n^2*s^2 + I_l*dm_m*k_g*n^2*s^2 + Im_m*d_l*k_g*n^2*s^2 + Im_g*dm_m*k_b*n^4*s^2 + Im_m*dm_g*k_b*n^4*s^2 + Im_g*dm_mg*k_b*n^4*s^2 + Im_m*dm_mg*k_b*n^4*s^2 + d_gl*d_l*dm_m*n^2*s^2 + d_gl*d_l*dm_mg*n^2*s^2 + d_gl*dm_g*dm_m*n^4*s^2 + d_gl*dm_g*dm_mg*n^4*s^2 + d_gl*dm_m*dm_mg*n^4*s^2 + d_l*dm_g*dm_m*n^4*s^2 + d_l*dm_g*dm_mg*n^4*s^2 + d_l*dm_m*dm_mg*n^4*s^2 + Im_g*k_b*k_g*n^2*s + Im_m*k_b*k_g*n^2*s + d_l*dm_m*k_b*n^2*s + d_gl*dm_g*k_g*n^2*s + d_l*dm_mg*k_b*n^2*s + d_gl*dm_m*k_g*n^2*s + d_l*dm_g*k_g*n^2*s + d_l*dm_m*k_g*n^2*s + dm_g*dm_m*k_b*n^4*s + dm_g*dm_mg*k_b*n^4*s + dm_m*dm_mg*k_b*n^4*s + I_l*Im_g*Im_m*n^4*s^5 + I_l*Im_m*d_gl*n^2*s^4 + Im_g*Im_m*d_gl*n^4*s^4 + I_l*Im_g*dm_m*n^4*s^4 + I_l*Im_m*dm_g*n^4*s^4 + Im_g*Im_m*d_l*n^4*s^4 + I_l*Im_g*dm_mg*n^4*s^4 + I_l*Im_m*dm_mg*n^4*s^4 + I_l*Im_m*k_b*n^2*s^3 + I_l*Im_g*k_g*n^2*s^3 + I_l*Im_m*k_g*n^2*s^3 + Im_g*Im_m*k_b*n^4*s^3),                                                                                                                                                                                                                                                                                                                                                      ((k_b + d_gl*s)*(k_g + dm_m*n^2*s + dm_mg*n^2*s + Im_m*n^2*s^2))/(d_l*k_b*k_g + d_gl*d_l*k_g*s + I_l*d_gl*k_g*s^2 + dm_g*k_b*k_g*n^2 + dm_m*k_b*k_g*n^2 + I_l*k_b*k_g*s + I_l*d_gl*dm_m*n^2*s^3 + Im_m*d_gl*d_l*n^2*s^3 + I_l*d_gl*dm_mg*n^2*s^3 + Im_g*d_gl*dm_m*n^4*s^3 + Im_m*d_gl*dm_g*n^4*s^3 + Im_g*d_gl*dm_mg*n^4*s^3 + Im_m*d_gl*dm_mg*n^4*s^3 + I_l*dm_g*dm_m*n^4*s^3 + Im_g*d_l*dm_m*n^4*s^3 + Im_m*d_l*dm_g*n^4*s^3 + I_l*dm_g*dm_mg*n^4*s^3 + Im_g*d_l*dm_mg*n^4*s^3 + I_l*dm_m*dm_mg*n^4*s^3 + Im_m*d_l*dm_mg*n^4*s^3 + I_l*dm_m*k_b*n^2*s^2 + Im_m*d_l*k_b*n^2*s^2 + Im_g*d_gl*k_g*n^2*s^2 + I_l*dm_mg*k_b*n^2*s^2 + Im_m*d_gl*k_g*n^2*s^2 + I_l*dm_g*k_g*n^2*s^2 + Im_g*d_l*k_g*n^2*s^2 + I_l*dm_m*k_g*n^2*s^2 + Im_m*d_l*k_g*n^2*s^2 + Im_g*dm_m*k_b*n^4*s^2 + Im_m*dm_g*k_b*n^4*s^2 + Im_g*dm_mg*k_b*n^4*s^2 + Im_m*dm_mg*k_b*n^4*s^2 + d_gl*d_l*dm_m*n^2*s^2 + d_gl*d_l*dm_mg*n^2*s^2 + d_gl*dm_g*dm_m*n^4*s^2 + d_gl*dm_g*dm_mg*n^4*s^2 + d_gl*dm_m*dm_mg*n^4*s^2 + d_l*dm_g*dm_m*n^4*s^2 + d_l*dm_g*dm_mg*n^4*s^2 + d_l*dm_m*dm_mg*n^4*s^2 + Im_g*k_b*k_g*n^2*s + Im_m*k_b*k_g*n^2*s + d_l*dm_m*k_b*n^2*s + d_gl*dm_g*k_g*n^2*s + d_l*dm_mg*k_b*n^2*s + d_gl*dm_m*k_g*n^2*s + d_l*dm_g*k_g*n^2*s + d_l*dm_m*k_g*n^2*s + dm_g*dm_m*k_b*n^4*s + dm_g*dm_mg*k_b*n^4*s + dm_m*dm_mg*k_b*n^4*s + I_l*Im_g*Im_m*n^4*s^5 + I_l*Im_m*d_gl*n^2*s^4 + Im_g*Im_m*d_gl*n^4*s^4 + I_l*Im_g*dm_m*n^4*s^4 + I_l*Im_m*dm_g*n^4*s^4 + Im_g*Im_m*d_l*n^4*s^4 + I_l*Im_g*dm_mg*n^4*s^4 + I_l*Im_m*dm_mg*n^4*s^4 + I_l*Im_m*k_b*n^2*s^3 + I_l*Im_g*k_g*n^2*s^3 + I_l*Im_m*k_g*n^2*s^3 + Im_g*Im_m*k_b*n^4*s^3);
                                                                                                                                                                                                                                                                                                                                                   (k_t*n*(k_b + d_gl*s)*(dm_mg*s*n^2 + k_g))/(d_l*k_b*k_g + d_gl*d_l*k_g*s + I_l*d_gl*k_g*s^2 + dm_g*k_b*k_g*n^2 + dm_m*k_b*k_g*n^2 + I_l*k_b*k_g*s + I_l*d_gl*dm_m*n^2*s^3 + Im_m*d_gl*d_l*n^2*s^3 + I_l*d_gl*dm_mg*n^2*s^3 + Im_g*d_gl*dm_m*n^4*s^3 + Im_m*d_gl*dm_g*n^4*s^3 + Im_g*d_gl*dm_mg*n^4*s^3 + Im_m*d_gl*dm_mg*n^4*s^3 + I_l*dm_g*dm_m*n^4*s^3 + Im_g*d_l*dm_m*n^4*s^3 + Im_m*d_l*dm_g*n^4*s^3 + I_l*dm_g*dm_mg*n^4*s^3 + Im_g*d_l*dm_mg*n^4*s^3 + I_l*dm_m*dm_mg*n^4*s^3 + Im_m*d_l*dm_mg*n^4*s^3 + I_l*dm_m*k_b*n^2*s^2 + Im_m*d_l*k_b*n^2*s^2 + Im_g*d_gl*k_g*n^2*s^2 + I_l*dm_mg*k_b*n^2*s^2 + Im_m*d_gl*k_g*n^2*s^2 + I_l*dm_g*k_g*n^2*s^2 + Im_g*d_l*k_g*n^2*s^2 + I_l*dm_m*k_g*n^2*s^2 + Im_m*d_l*k_g*n^2*s^2 + Im_g*dm_m*k_b*n^4*s^2 + Im_m*dm_g*k_b*n^4*s^2 + Im_g*dm_mg*k_b*n^4*s^2 + Im_m*dm_mg*k_b*n^4*s^2 + d_gl*d_l*dm_m*n^2*s^2 + d_gl*d_l*dm_mg*n^2*s^2 + d_gl*dm_g*dm_m*n^4*s^2 + d_gl*dm_g*dm_mg*n^4*s^2 + d_gl*dm_m*dm_mg*n^4*s^2 + d_l*dm_g*dm_m*n^4*s^2 + d_l*dm_g*dm_mg*n^4*s^2 + d_l*dm_m*dm_mg*n^4*s^2 + Im_g*k_b*k_g*n^2*s + Im_m*k_b*k_g*n^2*s + d_l*dm_m*k_b*n^2*s + d_gl*dm_g*k_g*n^2*s + d_l*dm_mg*k_b*n^2*s + d_gl*dm_m*k_g*n^2*s + d_l*dm_g*k_g*n^2*s + d_l*dm_m*k_g*n^2*s + dm_g*dm_m*k_b*n^4*s + dm_g*dm_mg*k_b*n^4*s + dm_m*dm_mg*k_b*n^4*s + I_l*Im_g*Im_m*n^4*s^5 + I_l*Im_m*d_gl*n^2*s^4 + Im_g*Im_m*d_gl*n^4*s^4 + I_l*Im_g*dm_m*n^4*s^4 + I_l*Im_m*dm_g*n^4*s^4 + Im_g*Im_m*d_l*n^4*s^4 + I_l*Im_g*dm_mg*n^4*s^4 + I_l*Im_m*dm_mg*n^4*s^4 + I_l*Im_m*k_b*n^2*s^3 + I_l*Im_g*k_g*n^2*s^3 + I_l*Im_m*k_g*n^2*s^3 + Im_g*Im_m*k_b*n^4*s^3),                                 (k_b*k_g + d_gl*k_g*s + dm_m*k_b*n^2*s + dm_mg*k_b*n^2*s + dm_g*k_g*n^2*s + dm_m*k_g*n^2*s + Im_g*Im_m*n^4*s^4 + Im_m*d_gl*n^2*s^3 + Im_g*dm_m*n^4*s^3 + Im_m*dm_g*n^4*s^3 + Im_g*dm_mg*n^4*s^3 + Im_m*dm_mg*n^4*s^3 + Im_m*k_b*n^2*s^2 + Im_g*k_g*n^2*s^2 + Im_m*k_g*n^2*s^2 + d_gl*dm_m*n^2*s^2 + d_gl*dm_mg*n^2*s^2 + dm_g*dm_m*n^4*s^2 + dm_g*dm_mg*n^4*s^2 + dm_m*dm_mg*n^4*s^2)/(d_l*k_b*k_g + d_gl*d_l*k_g*s + I_l*d_gl*k_g*s^2 + dm_g*k_b*k_g*n^2 + dm_m*k_b*k_g*n^2 + I_l*k_b*k_g*s + I_l*d_gl*dm_m*n^2*s^3 + Im_m*d_gl*d_l*n^2*s^3 + I_l*d_gl*dm_mg*n^2*s^3 + Im_g*d_gl*dm_m*n^4*s^3 + Im_m*d_gl*dm_g*n^4*s^3 + Im_g*d_gl*dm_mg*n^4*s^3 + Im_m*d_gl*dm_mg*n^4*s^3 + I_l*dm_g*dm_m*n^4*s^3 + Im_g*d_l*dm_m*n^4*s^3 + Im_m*d_l*dm_g*n^4*s^3 + I_l*dm_g*dm_mg*n^4*s^3 + Im_g*d_l*dm_mg*n^4*s^3 + I_l*dm_m*dm_mg*n^4*s^3 + Im_m*d_l*dm_mg*n^4*s^3 + I_l*dm_m*k_b*n^2*s^2 + Im_m*d_l*k_b*n^2*s^2 + Im_g*d_gl*k_g*n^2*s^2 + I_l*dm_mg*k_b*n^2*s^2 + Im_m*d_gl*k_g*n^2*s^2 + I_l*dm_g*k_g*n^2*s^2 + Im_g*d_l*k_g*n^2*s^2 + I_l*dm_m*k_g*n^2*s^2 + Im_m*d_l*k_g*n^2*s^2 + Im_g*dm_m*k_b*n^4*s^2 + Im_m*dm_g*k_b*n^4*s^2 + Im_g*dm_mg*k_b*n^4*s^2 + Im_m*dm_mg*k_b*n^4*s^2 + d_gl*d_l*dm_m*n^2*s^2 + d_gl*d_l*dm_mg*n^2*s^2 + d_gl*dm_g*dm_m*n^4*s^2 + d_gl*dm_g*dm_mg*n^4*s^2 + d_gl*dm_m*dm_mg*n^4*s^2 + d_l*dm_g*dm_m*n^4*s^2 + d_l*dm_g*dm_mg*n^4*s^2 + d_l*dm_m*dm_mg*n^4*s^2 + Im_g*k_b*k_g*n^2*s + Im_m*k_b*k_g*n^2*s + d_l*dm_m*k_b*n^2*s + d_gl*dm_g*k_g*n^2*s + d_l*dm_mg*k_b*n^2*s + d_gl*dm_m*k_g*n^2*s + d_l*dm_g*k_g*n^2*s + d_l*dm_m*k_g*n^2*s + dm_g*dm_m*k_b*n^4*s + dm_g*dm_mg*k_b*n^4*s + dm_m*dm_mg*k_b*n^4*s + I_l*Im_g*Im_m*n^4*s^5 + I_l*Im_m*d_gl*n^2*s^4 + Im_g*Im_m*d_gl*n^4*s^4 + I_l*Im_g*dm_m*n^4*s^4 + I_l*Im_m*dm_g*n^4*s^4 + Im_g*Im_m*d_l*n^4*s^4 + I_l*Im_g*dm_mg*n^4*s^4 + I_l*Im_m*dm_mg*n^4*s^4 + I_l*Im_m*k_b*n^2*s^3 + I_l*Im_g*k_g*n^2*s^3 + I_l*Im_m*k_g*n^2*s^3 + Im_g*Im_m*k_b*n^4*s^3);
                                                                                                                                                                                                                                                                                                                                     (k_t*n*(k_b + d_gl*s)*(dm_mg*s*n^2 + k_g)*(d_l + I_l*s))/(d_l*k_b*k_g + d_gl*d_l*k_g*s + I_l*d_gl*k_g*s^2 + dm_g*k_b*k_g*n^2 + dm_m*k_b*k_g*n^2 + I_l*k_b*k_g*s + I_l*d_gl*dm_m*n^2*s^3 + Im_m*d_gl*d_l*n^2*s^3 + I_l*d_gl*dm_mg*n^2*s^3 + Im_g*d_gl*dm_m*n^4*s^3 + Im_m*d_gl*dm_g*n^4*s^3 + Im_g*d_gl*dm_mg*n^4*s^3 + Im_m*d_gl*dm_mg*n^4*s^3 + I_l*dm_g*dm_m*n^4*s^3 + Im_g*d_l*dm_m*n^4*s^3 + Im_m*d_l*dm_g*n^4*s^3 + I_l*dm_g*dm_mg*n^4*s^3 + Im_g*d_l*dm_mg*n^4*s^3 + I_l*dm_m*dm_mg*n^4*s^3 + Im_m*d_l*dm_mg*n^4*s^3 + I_l*dm_m*k_b*n^2*s^2 + Im_m*d_l*k_b*n^2*s^2 + Im_g*d_gl*k_g*n^2*s^2 + I_l*dm_mg*k_b*n^2*s^2 + Im_m*d_gl*k_g*n^2*s^2 + I_l*dm_g*k_g*n^2*s^2 + Im_g*d_l*k_g*n^2*s^2 + I_l*dm_m*k_g*n^2*s^2 + Im_m*d_l*k_g*n^2*s^2 + Im_g*dm_m*k_b*n^4*s^2 + Im_m*dm_g*k_b*n^4*s^2 + Im_g*dm_mg*k_b*n^4*s^2 + Im_m*dm_mg*k_b*n^4*s^2 + d_gl*d_l*dm_m*n^2*s^2 + d_gl*d_l*dm_mg*n^2*s^2 + d_gl*dm_g*dm_m*n^4*s^2 + d_gl*dm_g*dm_mg*n^4*s^2 + d_gl*dm_m*dm_mg*n^4*s^2 + d_l*dm_g*dm_m*n^4*s^2 + d_l*dm_g*dm_mg*n^4*s^2 + d_l*dm_m*dm_mg*n^4*s^2 + Im_g*k_b*k_g*n^2*s + Im_m*k_b*k_g*n^2*s + d_l*dm_m*k_b*n^2*s + d_gl*dm_g*k_g*n^2*s + d_l*dm_mg*k_b*n^2*s + d_gl*dm_m*k_g*n^2*s + d_l*dm_g*k_g*n^2*s + d_l*dm_m*k_g*n^2*s + dm_g*dm_m*k_b*n^4*s + dm_g*dm_mg*k_b*n^4*s + dm_m*dm_mg*k_b*n^4*s + I_l*Im_g*Im_m*n^4*s^5 + I_l*Im_m*d_gl*n^2*s^4 + Im_g*Im_m*d_gl*n^4*s^4 + I_l*Im_g*dm_m*n^4*s^4 + I_l*Im_m*dm_g*n^4*s^4 + Im_g*Im_m*d_l*n^4*s^4 + I_l*Im_g*dm_mg*n^4*s^4 + I_l*Im_m*dm_mg*n^4*s^4 + I_l*Im_m*k_b*n^2*s^3 + I_l*Im_g*k_g*n^2*s^3 + I_l*Im_m*k_g*n^2*s^3 + Im_g*Im_m*k_b*n^4*s^3),                                                                                                                                                                                   -(n^2*(k_b + d_gl*s)*(dm_g*k_g + dm_m*k_g + Im_g*k_g*s + Im_m*k_g*s + dm_g*dm_m*n^2*s + dm_g*dm_mg*n^2*s + dm_m*dm_mg*n^2*s + Im_g*Im_m*n^2*s^3 + Im_g*dm_m*n^2*s^2 + Im_m*dm_g*n^2*s^2 + Im_g*dm_mg*n^2*s^2 + Im_m*dm_mg*n^2*s^2))/(d_l*k_b*k_g + d_gl*d_l*k_g*s + I_l*d_gl*k_g*s^2 + dm_g*k_b*k_g*n^2 + dm_m*k_b*k_g*n^2 + I_l*k_b*k_g*s + I_l*d_gl*dm_m*n^2*s^3 + Im_m*d_gl*d_l*n^2*s^3 + I_l*d_gl*dm_mg*n^2*s^3 + Im_g*d_gl*dm_m*n^4*s^3 + Im_m*d_gl*dm_g*n^4*s^3 + Im_g*d_gl*dm_mg*n^4*s^3 + Im_m*d_gl*dm_mg*n^4*s^3 + I_l*dm_g*dm_m*n^4*s^3 + Im_g*d_l*dm_m*n^4*s^3 + Im_m*d_l*dm_g*n^4*s^3 + I_l*dm_g*dm_mg*n^4*s^3 + Im_g*d_l*dm_mg*n^4*s^3 + I_l*dm_m*dm_mg*n^4*s^3 + Im_m*d_l*dm_mg*n^4*s^3 + I_l*dm_m*k_b*n^2*s^2 + Im_m*d_l*k_b*n^2*s^2 + Im_g*d_gl*k_g*n^2*s^2 + I_l*dm_mg*k_b*n^2*s^2 + Im_m*d_gl*k_g*n^2*s^2 + I_l*dm_g*k_g*n^2*s^2 + Im_g*d_l*k_g*n^2*s^2 + I_l*dm_m*k_g*n^2*s^2 + Im_m*d_l*k_g*n^2*s^2 + Im_g*dm_m*k_b*n^4*s^2 + Im_m*dm_g*k_b*n^4*s^2 + Im_g*dm_mg*k_b*n^4*s^2 + Im_m*dm_mg*k_b*n^4*s^2 + d_gl*d_l*dm_m*n^2*s^2 + d_gl*d_l*dm_mg*n^2*s^2 + d_gl*dm_g*dm_m*n^4*s^2 + d_gl*dm_g*dm_mg*n^4*s^2 + d_gl*dm_m*dm_mg*n^4*s^2 + d_l*dm_g*dm_m*n^4*s^2 + d_l*dm_g*dm_mg*n^4*s^2 + d_l*dm_m*dm_mg*n^4*s^2 + Im_g*k_b*k_g*n^2*s + Im_m*k_b*k_g*n^2*s + d_l*dm_m*k_b*n^2*s + d_gl*dm_g*k_g*n^2*s + d_l*dm_mg*k_b*n^2*s + d_gl*dm_m*k_g*n^2*s + d_l*dm_g*k_g*n^2*s + d_l*dm_m*k_g*n^2*s + dm_g*dm_m*k_b*n^4*s + dm_g*dm_mg*k_b*n^4*s + dm_m*dm_mg*k_b*n^4*s + I_l*Im_g*Im_m*n^4*s^5 + I_l*Im_m*d_gl*n^2*s^4 + Im_g*Im_m*d_gl*n^4*s^4 + I_l*Im_g*dm_m*n^4*s^4 + I_l*Im_m*dm_g*n^4*s^4 + Im_g*Im_m*d_l*n^4*s^4 + I_l*Im_g*dm_mg*n^4*s^4 + I_l*Im_m*dm_mg*n^4*s^4 + I_l*Im_m*k_b*n^2*s^3 + I_l*Im_g*k_g*n^2*s^3 + I_l*Im_m*k_g*n^2*s^3 + Im_g*Im_m*k_b*n^4*s^3)];
 


    verifyEqual(testCase,TFNom,TFSym);

end


% function testFunctionalityTwo(testCase)
% % Test specific code
% end
