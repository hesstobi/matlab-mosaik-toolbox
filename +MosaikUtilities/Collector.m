classdef Collector < MosaikAPI.Simulator
    %COLLECTOR A simple data collecotr that prints all data when the
    %simulation finishes.
    
    properties (Constant)
        model = 'Collector'
    end
    
    properties
        data = []
        step_size = 1
        save_path = []
        eid = []
    end
    
    methods 
		function sim = Collector(varargin)
            sim = sim@MosaikAPI.Simulator(varargin{:});
        end
        
        function value = meta(this)
            value = meta@MosaikAPI.Simulator(this);
                        
            value.models.(this.model).public = true;
            value.models.(this.model).attrs = {};
            value.models.(this.model).params = {};
            value.models.(this.model).any_inputs = true;
            
        end
        
    end
    
    methods
        
        function dscrList = create(this,num,model,varargin)
           if num>1 || ~isempty(this.eid)
               error('Can only create one instance of Collector.')
           end
           
           this.eid = model;
           
           s.eid = this.eid;
           s.type = this.model;
           dscrList = horzcat({s},{[]});
        end
        
               
                
        function new_time = step(this,time,inputs)
            
            inputs = inputs.(this.eid);
            
            names = cellfun(@(x) strcat(fieldnames(inputs.(x)),'__',x),fieldnames(inputs),'UniformOutput',false);
            names = vertcat(names{:});
            values = cellfun(@(x) struct2cell(inputs.(x)),fieldnames(inputs),'UniformOutput',false);
            values = vertcat(values{:});
            t = cell2table(values','VariableNames',names);
            t.time = time;
                    
            this.data = vertcat(this.data,t);
            
            new_time = time + this.step_size;
           
        end
        
        
        function get_data(~,~)
            error('The Collector can not return data');           
        end
        
                
        function delete(this)
           disp(this.data);
        end
        
    end
    
end

