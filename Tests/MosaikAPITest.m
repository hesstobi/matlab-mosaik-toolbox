classdef MosaikAPITest < matlab.unittest.TestCase
    %MOSAIKAPITEST Unit Test Class for Testing the Matlab High Level Mosiak
    % API
    %
    
    properties (Constant)
        simConstructorArgs = {'127.0.0.1:1234','debug',true}
    end
    
    methods (TestClassSetup)
        
        function addExampleSimToPath(testCase)
            p = path;
            testCase.addTeardown(@path,p)
            addpath(fullfile(fileparts(pwd),'Example'))
        end
        
    end
    
    
    methods (Test)
        
        function testInitFunction(testCase)
            args = MosaikAPITest.simConstructorArgs;
            sim = ExampleSim(args{:});
            
            args = {'UnitTest'};
            kwargs.step_size = round(100*rand);
            meta = sim.simSocketReceivedRequest({'init',args,kwargs});
            
            % Verify the simulator Object
            testCase.verifyEqual(sim.sid, args{1}, ...
                'Init method failed to correctly set sid');
            testCase.verifyEqual(sim.step_size, kwargs.step_size, ...
                'Init method failed to correctly set simulation parameter');
            
            % Verify the return meta struct
            testCase.verifyClass(meta,'struct', ...
                'returned meta has to be a sturct');
            
            testCase.verifyTrue(any(strcmp(fieldnames(meta),'api_version')), ...
                'Init method did not return api_version in meta struct');
            
            testCase.verifyTrue(any(strcmp(fieldnames(meta),'models')), ...
                'Init method did not return models in meta struct');
            testCase.verifyClass(meta.models,'struct', ...
                'models meta has to be a sturct');
            
            models = fieldnames(meta.models);
            testCase.verifyGreaterThanOrEqual(numel(models),1,...
                'The simulator has to provide a least one Model');
            
            for idx=1:numel(models)
                model = meta.models.(models{idx});
                testCase.verifyClass(model,'struct', ...
                    'model meta has to be a sturct');
                
                testCase.verifyTrue(any(strcmp(fieldnames(model),'public')),...
                    'public field missing in models meta struct');
                testCase.verifyClass(model.public,'logical', ...
                    'public field in model sturct has to be logical');
                
                testCase.verifyTrue(any(strcmp(fieldnames(model),'attrs')),...
                    'attrs field missing in models meta struct');
                testCase.verifyClass(model.attrs,'cell', ...
                    'attrs field in model sturct has to be a cell');
                sizeAttrs = size(model.attrs);
                testCase.verifyTrue(sizeAttrs(1)==1 || isempty(model.attrs),...
                    'attrs cell in model struct has to be a row vector or empty')
                testCase.verifyTrue(sizeAttrs(2)>=2 ||  isempty(model.attrs),...
                    'attrs cell has to be empty or have more than one element. Add a empty array to fix that.');
                
                testCase.verifyTrue(any(strcmp(fieldnames(model),'params')),...
                    'params field missing in models meta sturct');
                testCase.verifyClass(model.params,'cell', ...
                    'params field in model sturct has to be a cell');
                sizeParams = size(model.params);
                testCase.verifyTrue(sizeParams(1)==1 || isempty(model.params),...
                    'params cell in model struct has to be a row vector or empty')
                testCase.verifyTrue(sizeParams(2)>=2 || isempty(model.params),...
                    'params cell cell has to be empty or have more than one element. Add a empty array to fix that.');
                
            end
            
        end
        
        function testCreateFunction(testCase)
            sim_args = MosaikAPITest.simConstructorArgs;
            sim = ExampleSim(sim_args{:});
            
            
            num = ceil(rand*5)+1;
            model = sim.providedModels{1};
            modelWithoutPackageName = sim.providedModelsWithoutPackage{1};
            
            params = eval([model '.meta']);
            params = params.params(cellfun(@(x) ~isempty(x),params.params));
            kwargs = cell2struct(num2cell(100*rand(size(params))),params,2);
            args = {num, modelWithoutPackageName};
            
            list = sim.simSocketReceivedRequest({'create',args,kwargs});
            
            testCase.verifyNumElements(sim.entities,num,...
                'Simulator did not create correct number of entities');
            testCase.verifyTrue(all(cellfun(@(x) isa(x,model),sim.entities)), ...
                'Simulator did not create correct type of model entites');
            testCase.verifyEqual(numel(unique(cellfun(@(x) x.eid,sim.entities,'UniformOutput',false))),num,...
                'Simulator Models did not have unique eids');
            
            
            testCase.verifyClass(list,'cell', ...
                'The return value of the create function has to be a cell')
            sizeList = size(list);
            testCase.verifyEqual(sizeList(1),1,...
                'Return entities list has to be a row vector');
            testCase.verifyGreaterThanOrEqual(sizeList(2),2,...
                'Return entities list has to have more than one element. Add a empty array to fix that.');
            
            listentry = list{1};
            testCase.verifyClass(listentry,'struct', ...
                'Elemtes of the entities list has to be a struct');
            testCase.verifyTrue(any(strcmp(fieldnames(listentry),'eid')),...
                'Elements of the entities list has to have a eid field');
            testCase.verifyTrue(any(strcmp(fieldnames(listentry),'type')),...
                'Elements of the entities list has to have a type field');
            testCase.verifyEqual(listentry.type,modelWithoutPackageName,...
                'Entities list type field has a worng value');
            
            
        end
        
        
        function testGetDataFunction(testCase)
            args = MosaikAPITest.simConstructorArgs;
            sim = ExampleSim(args{:});
            
            num = 1;
            model = sim.providedModels{1};
            sim.create(num,model);
            
            model = sim.entities{1};
            eid = model.eid;
            attrs = model.get_attrs();
            
            output.(eid) = attrs;
            data = sim.simSocketReceivedRequest({'get_data',{output},{}});
            
            testCase.verifyClass(data,'struct',...
                'get_data function has to return a struct');
            testCase.verifyNumElements(data,num, ...
                'the number of enteties in the returned data as to be the same as requestes');
            testCase.verifyTrue(any(strcmp(fieldnames(data),eid)),...
                'The data form the requested entities is not in the results');
            testCase.verifyClass(data.(eid),'struct',...
                'The returned data of the entity has to be a struct');
            testCase.verifyTrue(all(strcmp(fieldnames(data.(eid))',attrs)),...
                'One or more attributes missing in the retunred data of the entity');
            for idx=1:numel(attrs)
                testCase.verifyEqual(data.(eid).(attrs{idx}),model.(attrs{idx}),...
                    'Value missmatch between model and returned data');
            end
            
            
        end
        
        
        function testStepFunctionWithData(testCase)
            
            args = MosaikAPITest.simConstructorArgs;
            sim = ExampleSim(args{:});
            
            num = 1;
            model = sim.providedModels{1};
            sim.create(num,model);
            
            req = loadjson('["step", [0, {"Model_0": {"val": {"Matlab-1.Model_0": 3}, "delta": {"Matlab-1.Model_0": 1}}}], {}]');
            time = sim.simSocketReceivedRequest(req);
            
            testCase.verifyGreaterThan(time,req{2}{1},...
                'Simulation step does not increase simulation time');
            
        end
        
        
        function testStepFunctionWithOutData(testCase)
            
             args = MosaikAPITest.simConstructorArgs;
            sim = ExampleSim(args{:});
            
            num = 1;
            model = sim.providedModels{1};
            sim.create(num,model);
            
            req = loadjson('["step", [0, {}], {}]');
            time = sim.simSocketReceivedRequest(req);
            
            testCase.verifyGreaterThan(time,req{2},...
                'Simulation step does not increase simulation time');
            
            
        end
        
    end
    
end

