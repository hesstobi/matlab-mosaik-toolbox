function res = test()
import matlab.unittest.TestSuite

testCase = SimSocketTest; res = run(testCase);
testCase = MosaikSimulatorTest; res = [res run(testCase)];
testCase = MosaikAPITest; res = [res run(testCase)];
testCase = SimulatorUtilitiesTest; res = [res run(testCase)];


end

%suiteFolder = TestSuite.fromFolder(pwd);
%result = run(suiteFolder)