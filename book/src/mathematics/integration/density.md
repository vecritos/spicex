# Definition of Mass of a Planar Lamina of Variable Density

if $\rho$ is a continous density function on the lamina corresponding to a plan in region $R$ then the mass $m$ of the lamina is given by 

$m = \int_R\int\rho(x,y)\delta A$

## Moments and Center of Mass of a Variable Density Planar Lamina

let $\rho$ be a continous density function on the planar lamina $R$ the moments of mass with respect to the x and y axes are 

$M_x = \int_R\int y\rho(x,y)\delta A$

and 

$M_y = \int_R\int x\rho(x,y)\delta A$

if $m$ is the mass of the lamina then teh center of mass is 

$(\bar{x},\bar{y}) = (\frac{M_y}{m},\frac{M_x}{m})$

if $R$ represents a simple plane region rathe than a lamina, then the point $(\bar{x},\bar{y})$ is called the centroid of the region

## Triple Integrals

rectangular to cylindrical

$\int\int_Q\int f(x,y,z)\delta V = \int_{\theta_1}^{\theta_2}\int_{g_1(\theta)}^{g_2(\theta)}\int_{h_1(r cos\theta, r sin\theta)}^{h_2(r cos\theta, r sin\theta)}{f(r cos\theta, r sin\theta, z)r\delta z\delta r\delta\theta}$

rectangular to spherical

$\int\int_Q\int f(x,y,z)\delta V = \int_{\theta_1}^{\theta_2}\int_{\phi_1}^{\phi_2}\int_{\rho_1}^{\rho_2}{f(\rho sin\phi cos\theta, \rho sin\phi sin\theta, \rho cos\phi)\rho^2sin\phi \delta\rho\delta\phi\delta\theta}$