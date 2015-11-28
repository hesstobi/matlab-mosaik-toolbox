classdef SimSocketDelegate < handle
    % SIMSOCKETDELEGATE   Abstract delegate class for SimSocket
    %   Provides methods for simulator superclasses to implement.
    
    methods (Abstract)

    	% Parses request and calls simulator function.
        %
        % Parameter:
        %  - request: String argument; request message.
        %
        % Return:
        %  - response: Cell object; simulator functions response.
        response = simSocketReceivedRequest(this,request);

    end
    
end
