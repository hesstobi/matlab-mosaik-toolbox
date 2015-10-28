classdef ModelSimulator < MosaikAPI.Simulator
    % MODELSIMULATOR   Handles model creation and stepping.
    %   Provides methods to create models, perform steps and obtain data.
    
    properties (Abstract)

       providedModels   % Models which are provided by the simulator

    end
    
    properties

       entities = {}    % Entities from all created model
       step_size        % Simulator step size

    end
    
    
    methods 
        
        function this = ModelSimulator(varargin)
            % Constructor of the class ModelSimulator
            %
            % Parameter:
            %  - varargin: Passes optional arguments to
            %              simulator superclass.
            %
            % Return:
            %  - this: ModelSimulator object

            this = this@MosaikAPI.Simulator(varargin{:});
            
        end
        
        function value = meta(this)
            % Creates meta struct.

            value = meta@MosaikAPI.Simulator(this);
           
            % Collect the meta information from the models.
            modelMeta = cellfun(@(x) eval([x '.meta']),this.providedModels,'UniformOutput',false);
            value.models = cell2struct(modelMeta,this.providedModelsWithoutPackage,2);
        
        end
        
        
    end
    
    methods (Access=protected)
        
        function eid = nextEidForModel(this,model)
            % Returns next unique entitiy id for model.
            
            % Creates cell with model types from current entities.
            modelsIdx = cellfun(@(x) x.modelName,this.entities,'UniformOutput',false);
            % Gets cells that match given model type.
            modelsIdx = strcmp(modelsIdx,model);
            
            % Creates cell with eids from all matching model types.
            eids = cellfun(@(x) x.eid,this.entities(modelsIdx),'UniformOutput',false);
            
            eid = 0;
            if ~isempty(eids)
                % Gets highest eid number from all matching model types and increase by one.
                eid = max(str2double(strrep(eids,[model '_'],'')))+1;
            end

            % Creates new eid with new number.
            eid = [model '_' num2str(eid)];
            
        end
        
        function dscrList = dscrListForEntities(this,varargin)
            % Returns entitiy id and corrsponding model type for given models.

            % Gets selected entities.
            e = this.entities(varargin{:});

            % Creates cell array with model eids.
            eids = cellfun(@(x) x.eid,e,'UniformOutput',false);
            % Creates cell array with model types
            types = cellfun(@(x) x.modelName,e,'UniformOutput',false);

            % Creates struct with fields 'eid' and 'type' and values eids and types.
            dscrList = cell2struct(vertcat(eids,types),{'eid','type'},1);
            % Creates cell array with model eid and model type for each model as cell.
            dscrList = arrayfun(@(x) x,dscrList','UniformOutput',false);
            % Adds empty cell at end for JSONLab.
            dscrList{end+1} = [];     

        end        
        
        function entities = entitiesWithEids(this,eids)
            % Returns model entities for given entitiy ids.
           
            if isa(eids,'char')
                eids = {eids};
            end
            
            simEids = cellfun(@(x) x.eid,this.entities,'UniformOutput',false);
            [~,~,labels] = unique([simEids(:); eids(:)],'stable');
            idx  = any(bsxfun(@eq,labels(1:numel(simEids))',labels(numel(simEids)+1:end)),1);
            
            entities = this.entities(idx);
           
        end

    end
    
    methods
        
        function dscrList = create(this,num,model,varargin)
            % Creates a given model a given time. Passes unspecified amount of arguments.

            % Get model function.
            modelFunc = this.functionForModelNameWithoutPackage(model);
                                 
            for idx=1:num
                % Get eid for model and add to entities.
                this.entities{end+1} = modelFunc(this,this.nextEidForModel(model),varargin{:});
            end
            
            % Create dscrList for previously created entities.
            dscrList = this.dscrListForEntities(numel(this.entities)-num+1:numel(this.entities));
        
        end
        
        function data = get_data(this,outputs)
            % Returns values for given attributes of given models.
                        
            eids = fieldnames(outputs);
            req_entities = this.entitiesWithEids(eids);
            values = cellfun(@(x,y) x.get_data(y),req_entities,struct2cell(outputs)','UniformOutput',false);
            data = cell2struct(values,eids',2);

        end
        
        function time_next_step = step(this,time,varargin)
            % Performs a step with given values for given attributes.
            
            if ~isempty(varargin)
                % Set data to entities.
                data = this.concentrateInputs(varargin{1});
                this.setEntitiesData(data);
            end
            
            % Perform a step with all entities.
            cellfun(@(x) x.step(time),this.entities);
            
            time_next_step = time + this.step_size;

        end
    
        
        function setEntitiesData(this,inputs)
            % Calls model 'set_data' method for given model entities and given values for given attributes.
            
            eids = fieldnames(inputs);
            req_entities = this.entitiesWithEids(eids);
            cellfun(@(x,y) x.set_data(y),req_entities,struct2cell(inputs)','UniformOutput',false);
                                
        end
        
        function value = providedModelsWithoutPackage(this)
            % Returns models name.

            % Creates cell array with second part of provided models name
            % Example: providedModels = {'Model.Battery',' Model.Load'}, value = {'Battery', 'Load'}
            value = cellfun(@(y) y{end},cellfun(@(x) strsplit(x,'.'), this.providedModels,'UniformOutput',false),'UniformOutput',false);
        
        end
            
        function value = fullNameForModelNameWithoutPackage(this,model)
            % Returns package and models name.

            % Compares model second name against given model name
            % Example: model = 'Battery', idx = [true, false], value = 'Model.Battery'
            idx = strcmp(this.providedModelsWithoutPackage,model);
            value = this.providedModels{idx};
        end
         
        function func = functionForModelNameWithoutPackage(this,model)
            % Returns full model name as function.

            func = str2func(this.fullNameForModelNameWithoutPackage(model));
        
        end         
        
    end
    
end
