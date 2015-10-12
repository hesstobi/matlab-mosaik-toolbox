classdef ModelSimulator < MosaikAPI.Simulator
    %MODELSIMULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
       providedModels 
    end
    
    properties
       entities = {} 
       step_size
    end
    
    
    methods 
		
        function this = ModelSimulator(varargin)
            this = this@MosaikAPI.Simulator(varargin{:});
        end
        
        function value = meta(this)
           value = meta@MosaikAPI.Simulator(this);
           
           % Collect the meta information from the models
           modelMeta = cellfun(@(x) eval([x '.meta']),this.providedModels,'UniformOutput',false);
           value.models = cell2struct(modelMeta,this.providedModelsWithoutPackage,2);
           
        end
        
        
    end
    
    methods (Access=protected)
        
        function eid = nextEidForModel(this,model)
            
                      
            modelsIdx = cellfun(@(x) x.modelName,this.entities,'UniformOutput',false);
            modelsIdx = strcmp(modelsIdx,model);
            
            eids = cellfun(@(x) x.eid,this.entities(modelsIdx),'UniformOutput',false);
            
            eid = 0;
            if ~isempty(eids)
                eid =max(str2double(strrep(eids,[model '_'],'')))+1;
            end
            
            eid = [model '_' num2str(eid)];
            
        end
        
        function dscrList = dscrListForEntities(this,varargin)
           
           e = this.entities(varargin{:});
           
           eids = cellfun(@(x) x.eid,e,'UniformOutput',false);
           types = cellfun(@(x) x.modelName,e,'UniformOutput',false);
           
           dscrList = cell2struct(vertcat(eids,types),{'eid','type'},1);
           dscrList = arrayfun(@(x) x,dscrList','UniformOutput',false);
           dscrList{end+1} = [];
          
           
        end
        
        
        function entities = entitiesWithEids(this,eids)
           
            if isa(eids,'char')
                eids = {eids};
            end
            
            simEids = cellfun(@(x) x.eid,this.entities,'UniformOutput',false);
            [~,~,labels] = unique([simEids(:); eids(:)],'stable');
            idx  = any(bsxfun(@eq,labels(1:numel(simEids))',labels(numel(simEids)+1:end)),1);
            
            entities = this.entities(idx);
           
        end
        
    end
    
    %% Mosaik API
    methods
       
        
        
        
        function dscrList = create(this,num,model,varargin)
            modelFunc = this.functionForModelNameWithoutPackage(model);
                                 
            for idx=1:num
                this.entities{end+1} = modelFunc(this.nextEidForModel(model),varargin{:});
            end
            
           
            dscrList = this.dscrListForEntities(numel(this.entities)-num+1:numel(this.entities));

        end
        
        
        function data = get_data(this, outputs)
						
            eids = fieldnames(outputs);
            req_entities = this.entitiesWithEids(eids);
            values = cellfun(@(x,y) x.get_data(y),req_entities,struct2cell(outputs)','UniformOutput',false);
            data = cell2struct(values,eids',2);  
          
        end
        
        function time_next_step = step(this,time,varargin)           
            
            if ~isempty(varargin)
                % Set data to entities
                data = this.concentrateInputs(varargin{1});
                this.setEntitiesData(data);
            end
            
            % Preform a step with all entities
            cellfun(@(x) x.step(time),this.entities);
            
			time_next_step = time + this.step_size;
		end
         
               
    end
    
        %% Utilities
    methods 
        
         function setEntitiesData(this,inputs)
            
             eids = fieldnames(inputs);
             req_entities = this.entitiesWithEids(eids);
             cellfun(@(x,y) x.set_data(y),req_entities,struct2cell(inputs)','UniformOutput',false);
                                
         end
        
         function value = providedModelsWithoutPackage(this)
            value = cellfun(@(y) y{end},cellfun(@(x) strsplit(x,'.'), this.providedModels,'UniformOutput',false),'UniformOutput',false);
         end
            
         function value = fullNameForModelNameWithoutPackage(this,model)
             idx = strcmp(this.providedModelsWithoutPackage,model);
             value = this.providedModels{idx};
         end
         
         function func = functionForModelNameWithoutPackage(this,model)
             func = str2func(this.fullNameForModelNameWithoutPackage(model));
         end
         
        
    end
    
    
    
    
end

