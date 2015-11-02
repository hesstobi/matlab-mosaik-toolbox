classdef MosaikSimulatorTest < matlab.unittest.TestCase
    %MOSAIKSIMULATORTEST Unit Test Class for Testing the Matlab High Level
    % Mosaik Simulator
    % API
    
    properties (Constant)
        simConstructorArgs = {'127.0.0.1:1234','debug',true}
    end
    
    properties
       simulator 
    end
    
     methods (TestClassSetup)
        
        function createSimulator(this)
            args = MosaikSimulatorTest.simConstructorArgs;
            this.simulator = TestSimulator(args{:});
        end
        
    end
    
    methods (Test)
        
        function testInitFunction(this)
            
            args = {'UnitTest'};
            kwargs.parameter1 = round(100*rand);
            kwargs.parameter2 = round(100*rand);
            meta = this.simulator.simSocketReceivedRequest({'init',args,kwargs});
            
            % Verify the simulator Object
            this.verifyEqual(this.simulator.sid, args{1}, ...
                'Init method failed to correctly set sid');
            this.verifyEqual(this.simulator.parameter1, kwargs.parameter1, ...
                'Init method failed to correctly set simulation parameter');
            this.verifyEqual(this.simulator.parameter2, kwargs.parameter2, ...
                'Init method failed to correctly set simulation parameter');
            
            % Verify the return meta struct
            this.verifyClass(meta,'struct', ...
                'returned meta has to be a sturct');
            
            this.verifyTrue(any(strcmp(fieldnames(meta),'api_version')), ...
                'Init method did not return api_version in meta struct');
            
            this.verifyTrue(any(strcmp(fieldnames(meta),'models')), ...
                'Init method did not return models in meta struct');
            this.verifyClass(meta.models,'struct', ...
                'models meta has to be a sturct');
            
        end
        
        
        function testCreateFunctionWithoutParameter(this)
            
            num = randi(10);
            model = 'Test';
            args = {num, model};
            out = this.simulator.simSocketReceivedRequest({'create',args,{}});
            
            this.verifyEqual(out.num,num);
            this.verifyEqual(out.model,model);
            this.verifyEmpty(out.params)
            
        end
        
        function testCreateFunctionWithParameter(this)
            
            num = randi(10);
            model = 'Test';
            args = {num, model};
            kwargs.p1 = 1;
            kwargs.p2 = 2;
            out = this.simulator.simSocketReceivedRequest({'create',args,kwargs});
            
            this.verifyEqual(out.num,num);
            this.verifyEqual(out.model,model);
            this.verifyEqual(out.params,{'p1',1,'p2',2});
        end
        
        
        function testStepFunction(this)
            
            time = randi(10);
            inputs = struct('a',1,'b',1);
            args = {time, inputs};
            out = this.simulator.simSocketReceivedRequest({'step',args,{}});
            
            this.verifyEqual(out.time,time);
            this.verifyEqual(out.inputs,inputs);
        end
        
        function testStepFunctionWithoutInputs(this)
            
            time = randi(10);
            args = time;
            out = this.simulator.simSocketReceivedRequest({'step',args,{}});
            
            this.verifyEqual(out.time,time);
            this.verifyEqual(out.inputs,'none');
        end
        
        
        function testGetDataFunction(this)
            
            output = struct('a',{{'b','c'}});
            args = {output};
            out = this.simulator.simSocketReceivedRequest({'get_data',args,{}});
            
            this.verifyEqual(out.output,output);
        end
        
    end
    
end

