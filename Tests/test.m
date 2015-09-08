import matlab.unittest.TestSuite

testCase = MosaikAPITest; res = run(testCase)
testCase = SimulatorUtilitiesTest; res = run(testCase)


%suiteFolder = TestSuite.fromFolder(pwd);
%result = run(suiteFolder)