# Definition of Surface Area

if $f$ and its first partial derivatives are continous on the closed region $R$ in the $xy-plane$ then the area of the surface $S$ given by $z=f(x,y)$ over $R$ is defined as 

$SurfaceArea = \int_R\int\delta S = \int_R\int \sqrt{1 + [f_x(x,y)]^2+[f_y(x,y)]^2}\delta A$

## Jacobians

$\int_R\int f(x,y)\delta A = \int_S\int f(g(u,v),h(u,v))\lvert \frac{\delta x}{\delta u}\frac{\delta y}{\delta v} - \frac{\delta y}{\delta u}\frac{\delta x}{\delta v}\rvert\delta u\delta v$