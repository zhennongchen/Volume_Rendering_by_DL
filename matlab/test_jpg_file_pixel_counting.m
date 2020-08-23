load([info.code_path,'/config_default']);
scale = [2 2 2];
figure('pos',[10 10 100 100])
config.Lighting = 0;
f = volshow(Data(1).seg_rot == 1,config,'ScaleFactors',scale);
saveas(gcf,'try.jpg')
count = Count_Non_White_Pixel('try.jpg',0);
