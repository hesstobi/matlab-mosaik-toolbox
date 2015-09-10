classdef SimulatorUtilitiesTest  < matlab.unittest.TestCase
    %SIMULATORUTILITIESTEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        simConstructorArgs = {'127.0.0.1:1234','debug',true}
    end
    
    methods (TestClassSetup)
        
        function addExampleSimToPath(testCase)
            p = path;
            testCase.addTeardown(@path,p)
            addpath(fullfile(fileparts(pwd),'Example','ExampleSim'))
        end
        
    end
    
    
    methods (Test)
        
        function testSetEntitiesDataFunction(testCase)
            args = MosaikAPITest.simConstructorArgs;
            sim = ExampleSim(args{:});
            
            % Create Models
            num = 5;
            model = sim.providedModels{1};
            sim.create(num,model);
            
            % Create Data to set to the Models
            set_models = sim.entities([1 3 5]);
            data = cell(size(set_models));
            get_data = cell(size(set_models));
            for idx = 1:numel(set_models)
               
                m = set_models{idx};
                attrs = m.get_attrs();
                get_data{idx} = attrs;
                data{idx} = cell2struct(num2cell(10*rand(size(attrs))),attrs,2);
            end
            data = cell2struct(data,cellfun(@(x) x.eid, set_models, 'UniformOutput',false),2);
            get_data = cell2struct(get_data,cellfun(@(x) x.eid, set_models, 'UniformOutput',false),2);

            % Set the data
            sim.setEntitiesData(data); 
            get_data = sim.get_data(get_data);
            
           
            
            % Tests
            testCase.verifyEqual(cell2mat(cellfun(@(x) cell2mat(struct2cell(x)),struct2cell(data),'UniformOutput',false)), ...
                cell2mat(cellfun(@(x) cell2mat(struct2cell(x)),struct2cell(get_data),'UniformOutput',false)),...
                'set_entities_data failed to set the right data');
            
        end 
        
        
        function testConcentrateInputs(testCase)
           
            data = loadjson('{ "dest1": { "attr1": {"scr1": 1, "scr2": 2, "scr3": 3}, "attr2": {"scr1": 4, "scr2": 5, "scr3": 6}, "attr3": {"scr1": 7, "scr2": 8, "scr3": 9} }, "dest2": { "attr1": {"scr1": 11, "scr2": 12, "scr3": 13}, "attr2": {"scr1": 14, "scr2": 15, "scr3": 16}, "attr3": {"scr1": 17, "scr2": 18, "scr3": 19} }, "dest3": { "attr1": {"scr1": 21, "scr2": 22, "scr3": 23}, "attr2": {"scr1": 24, "scr2": 25, "scr3": 26}, "attr3": {"scr1": 27, "scr2": 28, "scr3": 29} }}');
            res = [6;15;24;36;45;54;66;75;84];
            res_data = MosaikAPI.Simulator.concentrateInputs(data);
            
            testCase.verifyEqual(res,cell2mat(cellfun(@(x) cell2mat(struct2cell(x)),struct2cell(res_data),'UniformOutput',false)),...
                'failed to concentrate data correctly');
            

        end
        
    end
    
end

