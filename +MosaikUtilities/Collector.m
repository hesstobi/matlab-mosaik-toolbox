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
            fn = fieldnames(inputs);
            for i = 1:numel(fn)
                disp(fn{i})
                disp(inputs.(fn{i}));
            end
            
            names = cellfun(@(x) strcat(fieldnames(inputs.(x)),'_',x),fieldnames(inputs),'UniformOutput',false);
            names = cellfun(@(x) strrep(x,'_0x2D_','_'),names,'UniformOutput',false);   % Changing hex code to original symbol not allowed. Using '_' instead.
            names = cellfun(@(x) strrep(x,'_0x2E_','_'),names,'UniformOutput',false);
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
        
                
        function finalize(this)
            disp(this.data);

            if this.graphical_output
                x = this.data.time;
                this.data.time = [];
                names = this.data.Properties.VariableNames;
                types = cellfun(@(y) y{end},cellfun(@(x) strsplit(x,'_'),names,'UniformOutput',false),'UniformOutput',false);
                types = unique(types);
                for i = 1:numel(types)
                    typ = types{i};
                    figure('name',typ);
                    leg = {};
                    for j = 1:numel(names)
                        cur_typ = strsplit(names{j},'_');
                        cur_typ = cur_typ{end};
                        if strcmp(cur_typ,typ)
                            hold on;
                            plot(x,this.data.(names{j}));
                            name = strrep(names{j},['_' cur_typ],'');
                            leg(end+1) = {name};
                        end
                    end
                    set(legend(leg),'Interpreter','none');
                end
            end
            pause;
        end
        
    end
    
end

