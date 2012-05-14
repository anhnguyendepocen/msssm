function data = addAgentRepulsiveForce(data)
%ADDAGENTREPULSIVEFORCE Summary of this function goes here
%   Detailed explanation goes here

% Obstruction effects in case of physical interaction

% get maximum agent distance for which we calculate force
r_max = data.pixel_per_meter * ...
    fzero(@(r) data.A * exp((2*data.r_max-r)/data.B) - 1e-4, data.r_max);
tree = 0;

for fi = 1:data.floor_count
    pos = [arrayfun(@(a) a.p(1), data.floor(fi).agents);
           arrayfun(@(a) a.p(2), data.floor(fi).agents)];
    
    % update range tree of lower floor
    tree_lower = tree;
    % init range tree of current floor
    tree = tree_create(pos);
    
    agents_on_floor = length(data.floor(fi).agents);
    for ai = 1:agents_on_floor
        pi = data.floor(fi).agents(ai).p;
        vi = data.floor(fi).agents(ai).v;
        ri = data.floor(fi).agents(ai).r;
        
        % use range tree to get the indices of all agents near agent ai
        idx = tree_rangequery(tree, pi(1) - r_max, pi(1) + r_max, ...
                                    pi(2) - r_max, pi(2) + r_max)';
        
        % loop over agents near agent ai
        for aj = idx
            
            % if force has not been calculated yet...
            if aj > ai
                pj = data.floor(fi).agents(aj).p;
                vj = data.floor(fi).agents(aj).v;
                rj = data.floor(fi).agents(aj).r;

                % vector pointing from j to i
                nij = (pi - pj) * data.meter_per_pixel;

                % distance of agents
                d = norm(nij);

                % normalized vector pointing from j to i
                nij = nij / d;
                % tangential direction
                tij = [-nij(2), nij(1)];

                % sum of radii
                rij = (ri + rj);

                % repulsive interaction forces
                if d < rij
                   T1 = data.k*(rij - d);
                   T2 = data.kappa*(rij - d)*dot((vj - vi),tij)*tij;
                else
                   T1 = 0;
                   T2 = 0;
                end

                F =  (data.A * exp((rij - d)/data.B) + T1)*nij + T2;

                data.floor(fi).agents(ai).f = ...
                    data.floor(fi).agents(ai).f + F;
                data.floor(fi).agents(aj).f = ...
                    data.floor(fi).agents(aj).f - F;
            end
        end
        
        % include agents on stairs!
        if fi > 1
            % use range tree to get the indices of all agents near agent ai
            idx = tree_rangequery(tree_lower, pi(1) - r_max, ...
                    pi(1) + r_max, pi(2) - r_max, pi(2) + r_max)';
            
            % if there are any agents...
            if ~isempty(idx)
                for aj = idx
                    pj = data.floor(fi-1).agents(aj).p;
                    if data.floor(fi-1).img_stairs_up(round(pj(1)), round(pj(2)))

                        vj = data.floor(fi-1).agents(aj).v;
                        rj = data.floor(fi-1).agents(aj).r;

                        % vector pointing from j to i
                        nij = (pi - pj) * data.meter_per_pixel;

                        % distance of agents
                        d = norm(nij);

                        % normalized vector pointing from j to i
                        nij = nij / d;
                        % tangential direction
                        tij = [-nij(2), nij(1)];

                        % sum of radii
                        rij = (ri + rj);

                        % repulsive interaction forces
                        if d < rij
                           T1 = data.k*(rij - d);
                           T2 = data.kappa*(rij - d)*dot((vj - vi),tij)*tij;
                        else
                           T1 = 0;
                           T2 = 0;
                        end

                        F = (data.A * exp((rij - d)/data.B) + T1)*nij + T2;

                        data.floor(fi).agents(ai).f = ...
                            data.floor(fi).agents(ai).f + F;
                        data.floor(fi-1).agents(aj).f = ...
                            data.floor(fi-1).agents(aj).f - F;
                    end
                end
            end
        end
    end
end

