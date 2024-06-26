clear;close all;
fn_m_full = mfilename('fullpath');
[pn_m, fn_m] = fileparts(fn_m_full);
fn_dataabse = 'DataBase_filter.mat';
if ~exist([pn_m '\DataBase_filter.mat'],'file')
    DataBase_filter=[];
    save([pn_m '\DataBase_filter.mat'],'DataBase_filter');
end

pn_def = 'C:\Users\gengoro\SynologyDrive\Behavior\PTZ';
[fn_mov, pn_mov] = uigetfile([pn_def, '\*.avi'],'select *.avi');
yn_save_heavy_fig = 'n';%時間がかかる
yn_plot = input('yn_plot y/n \n','s');
%-------------------------------------------------------------------------
%パラメータ
Parameter.min_metric_std=2;
Parameter.Range = [ -1 -25];
Parameter.margin_start = 1;
Parameter.margin_stop = 1;
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%開いているfig取得
ListFigStart = findall(groot,'Type','figure');
%特徴点と代表特徴点の取得
[fn_black, fn_white, pn_d_movie, pn_filter] = make_d_movie([pn_mov, fn_mov]);%mov_white, mov_black作成。pn_filterは保存するフォルダ
mkdir([pn_filter '\Code']);copyfile(pn_m, [pn_filter '\Code']);

[Points_black, Pos_black] = get_movie_feature([pn_d_movie '\' fn_black],'DIM_select', [3]);%で特徴点検出, DIM_select [3]でZ軸のみスキャン
set(gcf,'Name','FeatureOFF','Color','w');
[Points_white, Pos_white] = get_movie_feature([pn_d_movie '\' fn_white],'DIM_select', [3]);%で特徴点検出
set(gcf,'Name','FeatureON','Color','w');
Salient.black  = find_salient(Points_black.z, Parameter.min_metric_std); %特徴点をMetricで絞る
Salient.white  = find_salient(Points_white.z, Parameter.min_metric_std); %特徴点をMetricで絞る
AllFeature.black = find_salient(Points_black.z, []); %特徴点をMetricで絞る, emptyなら全て
AllFeature.white  = find_salient(Points_white.z, []); %特徴点をMetricで絞る, emptyなら全て
if yn_plot == 'y'
    plot_salient(Salient.black, Salient.white, AllFeature.black, AllFeature.white);%表示
end
%-------------------------------------------------------------------------
%特徴点の軌跡の追跡
Pair.black = find_conn(Points_black.z);%最短距離でペアを探す
Pair.white = find_conn(Points_white.z);%最短距離でペアを探す
Points_seq.black = seq_connect(Pair.black,'Points',Points_black.z);%フレームをスキャンして、連続シークエンスを拾う
Points_seq.white = seq_connect(Pair.white,'Points',Points_white.z);%フレームをスキャンして、連続シークエンスを拾う

Points_Traj.black = find_featuretraj(Points_seq.black,Points_black.z,'yn_plot',yn_plot,'min_contig',3,'POS_overlay',Salient.black.Pos);%軌跡データを取得
set(gcf,'Name','Traj-Salient-OFF');
Points_Traj.white = find_featuretraj(Points_seq.white,Points_white.z,'yn_plot',yn_plot,'min_contig',3,'POS_overlay',Salient.white.Pos);%軌跡データを取得
set(gcf,'Name','Traj-Salient-ON');
%-------------------------------------------------------------------------
ListFigEnd = findall(groot,'Type','figure');%開いているfig取得
%-------------------------------------------------------------------------
% 保存
if yn_save_heavy_fig == 'y'
    ListFig = setdiff(ListFigEnd,ListFigStart);%保存するfig取得
    pn_save_fig = [pn_filter '\Fig'];
    mkdir(pn_save_fig);
    save_figs(ListFig,pn_save_fig);%Figを保存
    close(ListFig);
end
fn_save = 'FeatureTraj.mat';
save([pn_filter '\' fn_save],'Parameter','Salient','AllFeature','Pair','Points_seq','Points_Traj');
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
List_selectWB = {'b','w'};
for id_wb = 1:numel(List_selectWB)
    selectWB = List_selectWB{id_wb};
    ListFigStart = findall(groot,'Type','figure');%開いているfig取得
    switch selectWB 
	    case 'b'
            All_ref = AllFeature.black;
            All_search = AllFeature.white;
		    Points_Traj_ref = Points_Traj.black;
		    Points_Traj_search = Points_Traj.white;
            Salient_ref = Salient.black;
	    case 'w'
            All_ref = AllFeature.white;
            All_search = AllFeature.black;
		    Points_Traj_ref = Points_Traj.white;
		    Points_Traj_search = Points_Traj.black;
            Salient_ref = Salient.white;
    end
    %-------------------------------------------------------------------------
    PairOverlap = find_overlap(Salient_ref, All_search, All_ref,'Range',Parameter.Range);%重なるペアを探す
    %-------------------------------------------------------------------------
    if yn_plot == 'y'
        figure('Name','Ref Search trajectories overaly'); hold on;
        plot3(AllFeature.white.Pos(:,1), AllFeature.white.Pos(:,2),AllFeature.white.Pos(:,3),'k.');
        plot3(AllFeature.black.Pos(:,1), AllFeature.black.Pos(:,2),AllFeature.black.Pos(:,3),'m.');
        plot_traj(Points_Traj_ref,'c');
        plot_traj(Points_Traj_search,'m');
        legend({'ref','search'});
    end
    %-------------------------------------------------------------------------
    % どの軌跡に載っているか座標から探す
    clear Traj_ref;%変数クリア　重要
    for ii = 1:numel(Points_Traj_ref)
        Traj_ref{ii} = Points_Traj_ref(ii).pos;%cellfunが使えるようにまとめる。
    end
    clear Traj_found;%変数クリア　重要
    for ii = 1:numel(Points_Traj_search)
        Traj_found{ii} = Points_Traj_search(ii).pos;%cellfunが使えるようにまとめる。
    end
    
    List_POS = PairOverlap.ref.Location;
    Traj = Traj_ref;
    match_threshold = 1.5;%1.5ピクセル以内なら合っていると判断
    [ListTrajPos_ref_all]  = find_traj_by_pos(List_POS,Traj,match_threshold);%[その点を通る軌跡＃データと、点は軌跡内の何番目にあるか]複数の軌跡がヒットする
    [ListTrajPos_ref_temp]= find_longest_traj(ListTrajPos_ref_all,Traj,'e');% より早いフレームからつながっているもの選択。
    
    List_POS = PairOverlap.found.Location;
    Traj = Traj_found;
    match_threshold = 1.5;%1.5ピクセル以内なら合っていると判断
    [ListTrajPos_found_all]= find_traj_by_pos(List_POS,Traj,match_threshold);%[その点を通る軌跡＃データと、点は軌跡内の何番目にあるか]複数の軌跡がヒットする
    [ListTrajPos_found_temp] = find_longest_traj(ListTrajPos_found_all,Traj,'l');%より後のフレームまでつながっているものを選択
    
    ListExist = find(ListTrajPos_ref_temp(:,1).*ListTrajPos_ref_temp(:,2).*ListTrajPos_found_temp(:,1).*ListTrajPos_found_temp(:,2));%乗っている軌跡があったもの
    ListTrajPos_ref = ListTrajPos_ref_temp(ListExist,:);
    ListTrajPos_found = ListTrajPos_found_temp(ListExist,:);
    plot_paird_traj(Traj_ref,ListTrajPos_ref,Traj_found,ListTrajPos_found);%ペアの軌跡の確認プロット
    
    Points_Traj_pair.ref = Points_Traj_ref(ListTrajPos_ref(:,1));%使うTrajectoryデータのみセレクト
    Points_Traj_pair.found = Points_Traj_search(ListTrajPos_found(:,1));
    for id_pair = 1:numel(Points_Traj_pair.ref)
        Points_Traj_pair.ref(id_pair).peak = Points_Traj_pair.ref(id_pair).pos(ListTrajPos_ref(id_pair,2),3);%peakが軌跡の何番目かのデータも入れてまとめる
        Points_Traj_pair.found(id_pair).peak = Points_Traj_pair.found(id_pair).pos(ListTrajPos_found(id_pair,2),3);
    end
    %-------------------------------------------------------------------------
    %保存
    pn_save_onoff = [pn_filter, '\' selectWB];
    mkdir(pn_save_onoff);
    fn_save_onoff = 'PairTraj.mat';
    save([pn_save_onoff '/' fn_save_onoff],'Points_Traj_pair');
    
    ListFigEnd = findall(groot,'Type','figure');%開いているfig取得
    ListFig = setdiff(ListFigEnd,ListFigStart);%保存するfig取得
    pn_save_onoff_fig = [pn_save_onoff '\Fig'];
    mkdir(pn_save_onoff_fig);
    save_figs(ListFig,pn_save_onoff_fig);%Figを保存
    close (ListFig);

    load([pn_m '\DataBase_filter.mat']);

    yn_overwrite = 'n';
    if ~isempty(DataBase_filter)
        for id_data = 1:numel(DataBase_filter.pn_filter.top)
            fprintf('%d: %s\n',id_data, DataBase_filter.pn_filter.top{id_data});
        end
    end
    if ~isempty(DataBase_filter)
        IDMatch = find(cellfun(@(x) strcmp(pn_filter,x), DataBase_filter.pn_filter.top));
        if ~isempty(IDMatch)&&(selectWB =='b')%topが重なっていて、かつOFFのデータだったら（先に書き込むので）
            fprintf('This has been analyzed in %s\n', num2str(IDMatch));
            fprintf('Overwrite on %s\n' ,num2str(IDMatch));
            yn_overwrite = input('Overwrite y/n','s');
        else
            fprintf('This data is new \n');
        end
    end

    if isempty(DataBase_filter)
        current_number = 1;
    else
        if selectWB == 'b'
            if yn_overwrite == 'y'
                current_number =IDMatch;
            else
                current_number = input('Type number to write []= write on next cell\n');
                if isempty(current_number)
                    current_number = numel(DataBase_filter.pn_filter) + 1;
                end
            end
        end
    end

    if selectWB == 'b'
        yn_save = input('save y/n','s');
    end
    if yn_save == 'y'
        DataBase_filter.pn_filter.fn_mov_full{current_number} = [pn_mov '\' fn_mov];
        DataBase_filter.pn_filter.top{current_number} = pn_filter;
        DataBase_filter.pn_filter.(selectWB){current_number} = pn_save_onoff;
        DataBase_filter.(selectWB).Points_Traj_pair{current_number} = Points_Traj_pair;
        DataBase_filter.(selectWB).Parameter{current_number} = Parameter;
        save([pn_m '\DataBase_filter.mat'],'DataBase_filter');
    end
    
    %-------------------------------------------------------------------------
end
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
load([pn_m '\DataBase_filter.mat']);
for id_data = 1:numel(DataBase_filter.pn_filter.top)
    fprintf('%d: %s\n',id_data, DataBase_filter.pn_filter.top{id_data});
end

ListData = input('Type Input List\n');
for id_dataset = 1:numel(ListData)
    id_data = ListData(id_dataset);
    fprintf('Current file is %s\n',DataBase_filter.pn_filter.top{id_data});
    List_selectWB = {'b','w'};
    for id_wb = 1:numel(List_selectWB)
        selectWB = List_selectWB{id_wb};

        Points_Traj_pair = DataBase_filter.(selectWB).Points_Traj_pair{id_data};
        Parameter = DataBase_filter.(selectWB).Parameter{id_data};
        [MOV_onoff, Info_MOV_onoff] = make_moviefilter_from_traj(Points_Traj_pair.ref,Points_Traj_pair.found, Parameter.margin_start, Parameter.margin_stop, selectWB);%入力movie filterサンプル作成
        fprintf('N data for %s of %dth Data is %d\n',selectWB,id_dataset,numel(MOV_onoff));

        List_fields = fieldnames(Info_MOV_onoff);
        if id_dataset == 1
            MOV_onoff_stack.(selectWB) = MOV_onoff;
            Info_MOV_onoff_stack.(selectWB) = Info_MOV_onoff;
        else
            MOV_onoff_stack.(selectWB) = [MOV_onoff_stack.(selectWB), MOV_onoff];
            Info_MOV_onoff_stack.(selectWB).pix_max = [Info_MOV_onoff_stack.(selectWB).pix_max, Info_MOV_onoff.pix_max];
            Info_MOV_onoff_stack.(selectWB).pix_min = [Info_MOV_onoff_stack.(selectWB).pix_min, Info_MOV_onoff.pix_min];
            Info_MOV_onoff_stack.(selectWB).size = [Info_MOV_onoff_stack.(selectWB).size; Info_MOV_onoff.size];
        end
    end
end
for id_wb = 1:numel(List_selectWB)
    selectWB = List_selectWB{id_wb};
    fprintf('Total N for %s is %d\n',selectWB, numel(MOV_onoff_stack.(selectWB)));
end

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
if exist([pn_filter '\DataBase_SOM.mat'],'file')
    load([pn_filter '\DataBase_SOM.mat']);
    for id_data = 1:numel(DataBase_SOM.pn_filter.top)
        fprintf('%d: %s\n',id_data, DataBase_SOM.pn_filter.top{id_data});
    end
end

id_data_som =input('Type data# for saving\n');
DataBase_SOM.pn_filter.top = DataBase_filter.pn_filter.top;
DataBase_SOM.MOV_onoff_stack{id_data_som} = MOV_onoff_stack;
DataBase_SOM.MOV_onoff_stack{id_data_som} = MOV_onoff_stack;
DataBase_SOM.Info_MOV_onoff_stack{id_data_som} = Info_MOV_onoff_stack;
DataBase_SOM.ListData{id_data_som} = ListData;
for id_wb = 1:numel(List_selectWB)
    selectWB = List_selectWB{id_wb};
    MOV_adjust= format_moviefilter(MOV_onoff_stack.(selectWB),Info_MOV_onoff_stack.(selectWB),'rep_value','mode');%サイズ調整、最頻値に合わせる
    [MOV_som, rep_vec, net, ListFig]= som_movie_filter(MOV_adjust,'yn_plot',yn_plot);%自己組織化して、入力と結果表示

    DataBase_SOM.(selectWB).MOV_som{id_data_som} = MOV_som;
    DataBase_SOM.(selectWB).rep_vec{id_data_som} = rep_vec;
    DataBase_SOM.(selectWB).net{id_data_som} = net;
    DataBase_SOM.(selectWB).MOV_adjust{id_data_som} = MOV_adjust;
end
save([pn_filter '\DataBase_SOM.mat'],'DataBase_SOM');
%-------------------------------------------------------------------------
id_data_som =input('Type data#  export to DataBase[RFMap]\n');
id_dataset = 1;
clear DataBase;
for id_wb = 1:numel(List_selectWB)
    selectWB = List_selectWB{id_wb};
    DataBase{id_dataset}.input.RFMap = DataBase_SOM.(selectWB).MOV_som{id_data_som};
    DataBase{id_dataset}.yn_good = ones(size(DataBase{id_dataset}.input.RFMap,4),1);
    DataBase{id_dataset}.Rank = repmat({'A'}, 1,size(DataBase{id_dataset}.input.RFMap,4));
    DataBase{id_dataset}.datasetname = 'SOM';
    save([pn_filter '\DataBase_RFMap_' selectWB '.mat'],'DataBase');
end
h_start = gcf;
for id_map = 1:size(DataBase{id_dataset}.input.RFMap,4)
    figure('Name',['Map#' num2str(id_map)]);
    nFrame = size(DataBase{id_dataset}.input.RFMap,3);
    for id_frame = 1:nFrame
        range = max(abs(reshape(DataBase{id_dataset}.input.RFMap(:,:,:,id_map),[],1)));
        subplot(1,nFrame,id_frame);
        imagesc(DataBase{id_dataset}.input.RFMap(:,:,id_frame,id_map));
        clim([-range, range]);
    end
end
ListFig = setdiff(ListFig2,ListFig1);
fig_organizer(h_start.Number:h_end.Number);
ListGood = input('Type RF# to use m');
for id_wb = 1:numel(List_selectWB)
    selectWB = List_selectWB{id_wb};
    load([pn_filter '\DataBase_RFMap_' selectWB '.mat'],'DataBase');
    DataBase{id_dataset}.input.RFMap = DataBase{id_dataset}.input.RFMap(:,:,:,ListGood);
    DataBase{id_dataset}.yn_good = DataBase{id_dataset}.yn_good(ListGood);
    DataBase{id_dataset}.Rank = DataBase{id_dataset}.Rank(ListGood);
    save([pn_filter '\DataBase_RFMap_' selectWB '.mat'],'DataBase');
end
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
