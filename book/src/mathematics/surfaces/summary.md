# Summary of Line and Surface Integrals

## Line Integrals

$ds = \lvert\lvert r'(t) \rvert\rvert\delta t = \sqrt{[x'(t)]^2+[y'(t)]^2+[z'(t)]^2}\delta t$

scalar form 

$\int_{c}{f(x,y,z)\delta s} = \int_{a}^{b}{f(x(t), y(t), z(t))\delta s}

vector form 

$\int_{c}{F * \delta x} = \int_{c}{F * T} = \int_{a}^{b}{F(x(t), y(t), z(t)) * r'(t)\delta t}$

## Surface Integrals 

$z=g(x,y)$

$\delta S = \sqrt{1 + [g_x(x,y)]^2 + [g_y(x,y)]^2}\delta A$

scalar form

$\int_{S} \int f(x,y,z)\delta S = \int_{R} \int f(x,y,g(x,y))\sqrt{1+[g_x(x,y)]^2+[g_y(x,y)]^2}\delta A$

vector form (upward normal)

$\int_{S} \int F*N\delta S = \int_{R} \int F*[-g_x(x,y)i-g_y(x,y)j + k]\delta A$

## Surgace Integrals (parametric form)

$\delta S = \lvert\lvert r_u(u,v) \times r_v(u,v) \rvert\rvert\delta A$

scalar form

$\int_{S}\int f(x,y,z)\delta S = \int_{D}\int f(x(u,v), y(u,v), z(u,v))\delta S$

vector form

$\int_{S}\int F*N\delta S = \int_{D}\int F*(r_u\times r_v)\delta A$

## In Addition

$\int_{C}M\delta x + N\delta y = \int_{R}\int (\frac{\delta N}{\delta x} - \frac{\delta M}{\delta y})\delta A$