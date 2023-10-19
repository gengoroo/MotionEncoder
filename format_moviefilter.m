function MOV_adjust= format_moviefilter(MOV_onoff,Info_MOV_onoff,varargin)

    for ii = 1:nargin-2
        if strcmp('rep_value',varargin{ii})
            rep_value = varargin{ii+1};
        end
    end

    side_max = max(Info_MOV_onoff.size(:,1));
    dur_max = max(Info_MOV_onoff.size(:,3));
    switch rep_value
        case 'mode'
            side_mode = mode(Info_MOV_onoff.size(:,1));
            dur_mode = mode(Info_MOV_onoff.size(:,3));
    end
    
    clear MOV_adjust;
    for id_pair = 1:numel(MOV_onoff)
        %MOV_max = 0.5*ones(side_max,side_max,dur_max);
        MOV_max = zeros(side_max,side_max,dur_max);
        side = size(MOV_onoff{id_pair},1);
        dur = size(MOV_onoff{id_pair},3);
        xy_start = max(floor((side_max - side)/2),1);
        xy_stop = xy_start + side -1;
        z_start = dur_max - dur + 1;
        MOV_max(xy_start:xy_stop,xy_start:xy_stop,z_start:end) = MOV_onoff{id_pair};
    
        xy_start_crop = max(ceil((side_max - side_mode)/2),1);
        xy_stop_crop = xy_start_crop + side_mode -1;
        z_start_crop = dur_max - dur_mode + 1;
    
        MOV_adjust(:,:,:,id_pair) = MOV_max(xy_start_crop:xy_stop_crop,xy_start_crop:xy_stop_crop,z_start_crop:end);
    end

end