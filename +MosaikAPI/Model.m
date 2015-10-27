classdef Model < handle
    % MODEL  Superclass for models.
    %   Provides setter and getter methods and defines methodes that models need to implement.
    
    properties

        sim
        eid

    end
    
    methods

        function this = Model(sim,eid)
            % Constructor of the class Model.

            this.sim = sim;
            this.eid = eid;

        end        
        
        function data = get_data(this,attrs)
            
            attrs = unique(attrs);
            values = cellfun(@(x) this.(x),attrs,'UniformOutput',false);
            data = cell2struct(values,attrs,2);
 
        end        
        
        function set_data(this,data)

            attrs = fieldnames(data);

            values = struct2cell(data);
            
            for idx=1:numel(attrs)
                this.(attrs{idx}) = values{idx};
            end
            
        end        
        
        function value = get_attrs(this)
           
            value = this.meta().attrs;
            value = value(~cellfun(@isempty,value));
            
        end        
        
        function value = modelName(this)
            value = strsplit(class(this),'.');
            value = value{end};
        end
        
    end
 
    methods (Static,Abstract)

        value = meta();

    end
        
end
