classdef Model < handle
    % MODEL  Model superclass.
    %   Provides setter and getter methods and defines methodes that models need to implement.
    
    properties

        sim    % Associated simulator
        eid    % Models entitiy id

    end
    
    methods

        function this = Model(sim,eid)
            % Constructor of the class Model.

            this.sim = sim;
            this.eid = eid;

        end        
        
        function data = get_data(this,attrs)
            % Returns values for given attributes.
            
            attrs = unique(attrs);
            values = cellfun(@(x) this.(x),attrs,'UniformOutput',false);
            data = cell2struct(values,attrs,2);
 
        end        
        
        function set_data(this,data)
            % Sets given values for given attributes.

            attrs = fieldnames(data);

            values = struct2cell(data);
            
            for idx=1:numel(attrs)
                this.(attrs{idx}) = values{idx};
            end
            
        end        
        
        function value = get_attrs(this)
            % Returns all attributes of a model.
           
            value = this.meta().attrs;
            value = value(~cellfun(@isempty,value));
            
        end        
        
        function value = modelName(this)
            % Returns model name.

            value = strsplit(class(this),'.');
            value = value{end};

        end
        
    end
 
    methods (Static,Abstract)

        value = meta();
        % Abstract model meta creation method.

    end
        
end
