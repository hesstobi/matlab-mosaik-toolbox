classdef Collector < MosaikAPI.Simulator
    %COLLECTOR   A simple data collector that prints all data when the simulation finishes.
    
    properties (Constant)
        model = 'Collector';
    end
    
    properties
        data = [];
        step_size = 1;
        save_path = [];
        eid = [];
        graphical_output = false;
    end
    
    methods 
		function this = Collector(varargin)
            this = this@MosaikAPI.Simulator(varargin{:});
        end
        
        function value = meta(this)
            value = meta@MosaikAPI.Simulator(this);
                        
            value.models.(this.model).public = true;
            value.models.(this.model).attrs = {};
            value.models.(this.model).params = {'graphical_output',[]};
            value.models.(this.model).any_inputs = true;
            
        end
        
    end
    
    methods
        
        function dscrList = create(this,num,model,varargin)
            if num>1 || ~isempty(this.eid)
                error('Can only create one instance of Collector.')
            end

            p = inputParser;
            addOptional(p,'graphical_output',false,@(x)validateattributes(x,{'logical'},{'nonempty'}));
            parse(p,varargin{:});
            
            this.graphical_output = p.Results.graphical_output;           
            this.eid = model;
           
            s.eid = this.eid;
            s.type = this.model;
            dscrList = horzcat({s},{[]});
        end
        
               
                
        function new_time = step(this,time,inputs)
            
            inputs = inputs.(this.eid);
            
            names = cellfun(@(x) strcat(fieldnames(inputs.(x)),'__',x),fieldnames(inputs),'UniformOutput',false);
            disp(names);
            names = vertcat(names{:});
            disp(names);
            values = cellfun(@(x) struct2cell(inputs.(x)),fieldnames(inputs),'UniformOutput',false);
            disp(values);
            values = vertcat(values{:});
            disp(values);
            t = cell2table(values','VariableNames',names);
            t.time = time;
                    
            this.data = vertcat(this.data,t);
            
            new_time = time + this.step_size;
           
        end
        
        
        function get_data(~,~)
            error('The Collector can not return data');           
        end
        
                
        function finalize(this)
            disp(this.data);
            if this.graphical_output
                x = this.data.time;
                this.data.time = [];
                names = this.data.Properties.VariableNames;
                for i = 1:numel(names)
                    figure;
                    plot(x,this.data.(names{i}));
                    set(legend(names(i)), 'Interpreter', 'none');
                end
            end
            pause;
        end
        
    end
    
end

