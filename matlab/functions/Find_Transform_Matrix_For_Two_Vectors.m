function [r1,matrix1,r2,matrix2] = Find_Transform_Matrix_For_Two_Vectors(v1,v2)
r1 = vrrotvec(v1,v2);
matrix1 = vrrotvec2mat(r1);

r2 = r1;
matrix2 = matrix1;
            