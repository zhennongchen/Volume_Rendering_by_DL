function [r1,matrix1,r2,matrix2] = Find_Transform_Matrix_For_Two_Vectors(v1,v2)
r1 = vrrotvec(v1,v2);
matrix1 = vrrotvec2mat(r1);


r2 = 1;
v = cross(v1,v2);
s = norm(v);
c = dot(v1,v2);
I = [1 0 0;0 1 0;0 0 1];
vx = [0 -v(3) v(2); v(3) 0 -v(1);-v(2) v(1) 0];
matrix2 = I + vx + (vx.^2) * (1/(1+c));

            