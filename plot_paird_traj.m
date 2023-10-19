function plot_paird_traj(Traj_ref,ListTrajPos_ref,Traj_found,ListTrajPos_found)
    figure('Name','Paired trajectories');hold on;
    for ii = 1:size(ListTrajPos_ref,1)
        id_traj = ListTrajPos_ref(ii,1);
        id_pos = ListTrajPos_ref(ii,2);
        plot3(Traj_ref{id_traj}(:,1),Traj_ref{id_traj}(:,2),Traj_ref{id_traj}(:,3),'k');
        text(Traj_ref{id_traj}(1,1),Traj_ref{id_traj}(1,2),Traj_ref{id_traj}(1,3),['#' num2str(id_traj)]);
        plot3(Traj_ref{id_traj}(id_pos,1),Traj_ref{id_traj}(id_pos,2),Traj_ref{id_traj}(id_pos,3),'k*');
    
        id_traj_ref = id_traj;
        id_pos_ref = id_pos;
    
        id_traj = ListTrajPos_found(ii,1);
        id_pos = ListTrajPos_found(ii,2);
        plot3(Traj_found{id_traj}(:,1),Traj_found{id_traj}(:,2),Traj_found{id_traj}(:,3),'r');
        text(Traj_found{id_traj}(1,1),Traj_found{id_traj}(1,2),Traj_found{id_traj}(1,3),['#' num2str(id_traj)], 'Color','r');
        plot3(Traj_found{id_traj}(id_pos,1),Traj_found{id_traj}(id_pos,2),Traj_found{id_traj}(id_pos,3),'r*');
        id_traj_found = id_traj;
        id_pos_found = id_pos;
    
        plot3([Traj_ref{id_traj_ref}(id_pos_ref,1),Traj_found{id_traj_found}(id_pos_found,1)],...
            [Traj_ref{id_traj_ref}(id_pos_ref,2),Traj_found{id_traj_found}(id_pos_found,2)],...
            [Traj_ref{id_traj_ref}(id_pos_ref,3),Traj_found{id_traj_found}(id_pos_found,3)], 'g');
    end
    legend({'ref','','found',''});
end