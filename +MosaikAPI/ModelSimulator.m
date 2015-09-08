classdef ModelSimulator < MosaikAPI.Simulator
    %MODELSIMULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
       providedModels 
    end
    
    properties
       entities = {} 
    end
    
    
    methods 
		
        function sim = ModelSimulator(varargin)
            sim = sim@MosaikAPI.Simulator(varargin{:});
        end
        
        function value = meta(this)
           value = meta@MosaikAPI.Simulator(this);
           
           % Collect the meta information from the models
           modelMeta = cellfun(@(x) eval([x '.meta']),this.providedModels,'UniformOutput',false);
           value.models = cell2struct(modelMeta,this.providedModelsWithoutPackage,2);
           
        end
        
        
    end
    
    methods (Access=protected)
        
        function eid = nextEidForModel(sim,model)
            
                      
            modelsIdx = cellfun(@(x) x.modelName,sim.entities,'UniformOutput',false);
            modelsIdx = strcmp(modelsIdx,model);
            
            eids = cellfun(@(x) x.eid,sim.entities(modelsIdx),'UniformOutput',false);
            
            eid = 0;
            if ~isempty(eids)
                eid =max(str2double(strrep(eids,[model '_'],'')))+1;
            end
            
            eid = [model '_' num2str(eid)];
            
        end
        
        function dscrList = dscrListForEntities(sim,varargin)
           
           e = sim.entities(varargin{:});
           
           eids = cellfun(@(x) x.eid,e,'UniformOutput',false);
           types = cellfun(@(x) x.modelName,e,'UniformOutput',false);
           
           dscrList = cell2struct(vertcat(eids,types),{'eid','type'},1);
           dscrList = arrayfun(@(x) x,dscrList','UniformOutput',false);
           dscrList{end+1} = [];
          
           
        end
        
        
        function entities = entitiesWithEids(sim,eids)
           
            if isa(eids,'char')
                eids = {eids};
            end
            
            simEids = cellfun(@(x) x.eid,sim.entities,'UniformOutput',false);
            [~,~,labels] = unique([simEids(:); eids(:)],'stable');
            idx  = any(bsxfun(@eq,labels(1:numel(simEids))',labels(numel(simEids)+1:end)),1);
            
            entities = sim.entities(idx);
           
        end
        
    end
    
    %% Mosaik API
    methods
       
        
        
        
        function dscrList = create(sim,num,model,varargin)
            modelFunc = sim.functionForModelNameWithoutPackage(model);
                                 
            for idx=1:num
                sim.entities{end+1} = modelFunc(sim.nextEidForModel(model),varargin{:});
            end
            
           
            dscrList = sim.dscrListForEntities(numel(sim.entities)-num+1:numel(sim.entities));

        end
        
        
        function data = get_data(sim, outputs)
						
            eids = fieldnames(outputs);
            req_entities = sim.entitiesWithEids(eids);
            values = cellfun(@(x,y) x.get_data(y),req_entities,struct2cell(outputs)','UniformOutput',false);
            data = cell2struct(values,eids',2);  
          
        end
        
        function time_next_step = step(sim,time,varargin)           
            
            if ~isempty(varargin)
                % Set data to entities
                data = sim.concentrateInputs(varargin{1});
                sim.setEntitiesData(data);
            end
            
            % Preform a step with all entities
            cellfun(@(x) x.step(time),sim.entities);
            
			time_next_step = time + sim.step_size;
		end
         
               
    end
    
        %% Utilities
    methods 
        
         function setEntitiesData(sim,inputs)
            
             eids = fieldnames(inputs);
             req_entities = sim.entitiesWithEids(eids);
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

