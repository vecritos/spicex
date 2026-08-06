\documentclass{article}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{tikz}
\usetikzlibrary{arrows.meta, positioning}

\begin{document}

\section*{Human-Error Chaos Model with Operative Monitoring}

\subsection*{Variables and Parameters}

\begin{align*}
n_s &\quad \text{number of small mistakes (background human errors)} \\
n_L &\quad \text{number of large mistakes (major inflection points)} \\
M &\quad \text{number of operatives monitoring the system} \\[1mm]

s_i(t) &\quad \text{impact of small mistake } i \text{ at time } t, \quad i=1,\dots,n_s \\
L_j(t) &\quad \text{impact of large mistake } j \text{ at time } t, \quad j=1,\dots,n_L \\
\alpha_i &\quad \text{weight/importance of small mistake } i \\
\beta_j &\quad \text{weight/importance of large mistake } j \\[1mm]

p_{k,i} &\quad \text{probability operative } k \text{ notices small mistake } i \\
p_{k,j} &\quad \text{probability operative } k \text{ notices large mistake } j \\[1mm]

P_i &\quad \text{combined probability any operative notices small mistake } i \\
P_j &\quad \text{combined probability any operative notices large mistake } j \\[1mm]

x_t &\quad \text{system vulnerability / accumulated risk at time } t \\
\varepsilon_t &\quad \text{random noise / unpredictable fluctuations} \\[1mm]

H_t &\quad \text{entropy (measure of system uncertainty) at time } t \\
\gamma &\quad \text{conversion factor from vulnerability to entropy loss} \\
\kappa &\quad \text{scaling constant for probability of compromise}
\end{align*}

\subsection*{Equations}

\textbf{Aggregate probability for each mistake:}
\begin{align*}
P_i &= 1 - \prod_{k=1}^{M} (1 - p_{k,i}), \quad i=1,\dots,n_s \\
P_j &= 1 - \prod_{k=1}^{M} (1 - p_{k,j}), \quad j=1,\dots,n_L
\end{align*}

\textbf{System update (vulnerability accumulation):}
\begin{align*}
x_{t+1} &= x_t 
+ \sum_{i=1}^{n_s} \alpha_i \, P_i \, s_i(t)
+ \sum_{j=1}^{n_L} \beta_j \, P_j \, L_j(t)
+ \varepsilon_t
\end{align*}

\textbf{Entropy update:}
\begin{align*}
H_{t+1} &= H_t - \gamma \, x_{t+1}
\end{align*}

\textbf{Probability of compromise over 17-year horizon:}
\begin{align*}
\Pr(\text{break}) &= 1 - \exp\Big(-\kappa \, 2^{-H_{t+1}}\Big)
\end{align*}

\subsection*{Flow Diagram}

\begin{center}
\begin{tikzpicture}[
    node distance=2cm, 
    every node/.style={draw, rounded corners, align=center}, 
    >=Stealth
]

% Nodes
\node (small) {Small Mistakes\\$s_i(t)$, $i=1\dots n_s$};
\node[right=2cm of small] (large) {Large Mistakes\\$L_j(t)$, $j=1\dots n_L$};
\node[below=1.5cm of $(small)!0.5!(large)$] (operative) {Operatives\\$p_{k,i}, p_{k,j}$\\$k=1\dots M$};
\node[below=2cm of operative] (vuln) {Vulnerability Update\\$x_{t+1} = x_t + \dots$};
\node[below=2cm of vuln] (entropy) {Entropy Update\\$H_{t+1} = H_t - \gamma x_{t+1}$};
\node[below=2cm of entropy] (prob) {Probability of Compromise\\$\Pr(\text{break}) = 1 - e^{-\kappa 2^{-H_{t+1}}}$};

% Arrows
\draw[->] (small) -- (operative);
\draw[->] (large) -- (operative);
\draw[->] (operative) -- (vuln);
\draw[->] (vuln) -- (entropy);
\draw[->] (entropy) -- (prob);

\end{tikzpicture}
\end{center}

\end{document}
