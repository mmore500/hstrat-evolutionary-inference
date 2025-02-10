\ProvidesClass{artificial-lifex}[2022/01/12 v1.1 Artificial Life Journal Class]
\LoadClass[10.5pt,letterpaper]{article} % Font size and paper type
\usepackage[english]{babel}

% This class provides the template for the Artificial Life journal.
%   See full submission guidelines at
%   https://direct.mit.edu/artl/pages/submission-guidelines

%--------------------------------------------------%
%                 packages                         %
%                                                  %
%--------------------------------------------------%
% Document Formatting
\usepackage[margin=1in]{geometry}  % Page Margins
\usepackage{parskip}        % Natural paragraphs
\usepackage{setspace}       % Double Space
\usepackage{varwidth}       % To center affiliations
\usepackage{lineno}         % Add line numbers

% Links
\usepackage{url}            % Helpful for URLs
\usepackage{hyperref}       % Helpful for URLs

% bibliography
% gives utf8 support for accents in names, ignored with utf8 based engines
%\usepackage[utf8]{inputenc}
\usepackage{csquotes}		% rqd by babel to format quotes correctly

% Additional
% \usepackage{enumitem}       % Better lists

%--------------------------------------------------%
%                 Fonts                            %
%                                                  %
%--------------------------------------------------%

% \usepackage{fontspec}      % Required for custom font

% .ttf files required
% \setmainfont{AtkinsonHyperlegible}[
% Extension = .ttf,
% UprightFont = *-Regular,
% BoldFont = *-Bold,
% ItalicFont = *-Italic,
% BoldItalicFont = *-BoldItalic]


%--------------------------------------------------%
%           Some Convenient Shortcuts              %
%                                                  %
%--------------------------------------------------%

% \newcommand{\twitter}[1]{(\texttt{@#1})}
% \newcommand{\affil}[1]{\textsuperscript{#1}}

%--------------------------------------------------%
%           New Commands for Cover Page            %
%                                                  %
%--------------------------------------------------%

\newcommand{\@abs}{}
\newcommand{\abs}[1]{\gdef\@abs{%
    \begin{minipage}{0.8\textwidth}
        \doublespacing
        \textbf{Abstract. }#1
    \end{minipage}
    }}

\newcommand{\@keywords}{}
\newcommand{\keywords}[1]{\gdef\@keywords{%
    \begin{minipage}{0.8\textwidth}
        \textbf{Keywords:} \hspace{1em} #1
    \end{minipage}
    }}

\newcommand{\@auth}{}
\newcommand{\auth}[1]{\gdef\@auth{#1}}

\newcommand{\@corresponding}{}
\newcommand{\corresponding}[2]{\gdef\@corresponding{
    \textbf{Corresponding:} #1 (\texttt{#2})
}}

\newcommand{\@affiliations}{}
\newcommand{\affiliations}[1]{\gdef\@affiliations{
    \begin{varwidth}{\textwidth}
    \begin{enumerate}[]
    #1
    \end{enumerate}
    \end{varwidth}
    }}

%--------------------------------------------------%
%                Make Cover                        %
%                                                  %
%--------------------------------------------------%
\newcommand{\coverpage}{
    \begin{titlepage}
        \begin{center}
            % Header
            {\small \textit{Artificial Life} Manuscript Submission \par}
            % Title
            {\large \@title \par}
            \vspace{1cm}
            % List of authors
            {\@auth \par}
            {\@corresponding \par}
            \vspace{0.5cm}
            % List of affiliations
            {\footnotesize \@affiliations \par}
            \vspace{1cm}
            % Abstract
            {\@abs \par}
            \vspace{1cm}
            % Keywords
            {\@keywords \par}
            \vfill
        \end{center}
    \end{titlepage}
}
