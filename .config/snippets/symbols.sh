#!/bin/sh

addPrefixedFunction 'symbols' 'ls'   'left single quote ‘'
addPrefixedFunction 'symbols' 'rs'   'left single quote ’'
addPrefixedFunction 'symbols' 'ld'   'left double quote “'
addPrefixedFunction 'symbols' 'rd'   'left double quote ”'
symbols_ls() { printf %s ‘; }
symbols_rs() { printf %s ’; }
symbols_ld() { printf %s “; }
symbols_rd() { printf %s ”; }

addPrefixedFunction 'symbols' 'section'   'section sign §'
symbols_section() { printf %s §; }
addPrefixedFunction 'symbols' 'pilcrow'   'paragraph mark ¶'
symbols_pilcrow() { printf %s ¶; }

addPrefixedFunction 'symbols' 'fig'   'figure dash ‒'
symbols_em() { printf %s —; }
symbols_en() { printf %s –; }
symbols_fig() { printf %s –; }

# The greek symbols
# Greek symbols, I probably will not learn a Greek keyboard so yeah...
addPrefixedFunction 'symbols' 'Alpha'   'Alpha Α'
addPrefixedFunction 'symbols' 'alpha'   'alpha α'
addPrefixedFunction 'symbols' 'Beta'    'Beta Β'
addPrefixedFunction 'symbols' 'beta'    'beta β'
addPrefixedFunction 'symbols' 'Gamma'   'Gamma Γ'
addPrefixedFunction 'symbols' 'gamma'   'gamma γ'
addPrefixedFunction 'symbols' 'Delta'   'Delta Δ'
addPrefixedFunction 'symbols' 'delta'   'delta δ'
addPrefixedFunction 'symbols' 'Epsilon' 'Epsilon Ε'
addPrefixedFunction 'symbols' 'epsilon' 'epsilon ε'
addPrefixedFunction 'symbols' 'Zeta'    'Zeta Ζ'
addPrefixedFunction 'symbols' 'zeta'    'zeta ζ'
addPrefixedFunction 'symbols' 'Eta'     'Eta Η'
addPrefixedFunction 'symbols' 'eta'     'eta η'
addPrefixedFunction 'symbols' 'Theta'   'Theta Θ'
addPrefixedFunction 'symbols' 'theta'   'theta θ'
addPrefixedFunction 'symbols' 'Iota'    'Iota Ι'
addPrefixedFunction 'symbols' 'iota'    'iota ι'
addPrefixedFunction 'symbols' 'Kappa'   'Kappa Κ'
addPrefixedFunction 'symbols' 'kappa'   'kappa κ'
addPrefixedFunction 'symbols' 'Lambda'  'Lambda Λ'
addPrefixedFunction 'symbols' 'lambda'  'lambda λ'
addPrefixedFunction 'symbols' 'Mu'      'Mu Μ'
addPrefixedFunction 'symbols' 'mu'      'mu μ'
addPrefixedFunction 'symbols' 'Nu'      'Nu Ν'
addPrefixedFunction 'symbols' 'nu'      'nu ν'
addPrefixedFunction 'symbols' 'Xi'      'Xi Ξ'
addPrefixedFunction 'symbols' 'xi'      'xi ξ'
addPrefixedFunction 'symbols' 'Omicron' 'Omicron Ο'
addPrefixedFunction 'symbols' 'omicron' 'omicron ο'
addPrefixedFunction 'symbols' 'Pi'      'Pi Π'
addPrefixedFunction 'symbols' 'pi'      'pi π'
addPrefixedFunction 'symbols' 'Rho'     'Rho Ρ'
addPrefixedFunction 'symbols' 'rho'     'rho ρ'
addPrefixedFunction 'symbols' 'Sigma'   'Sigma Σ'
addPrefixedFunction 'symbols' 'sigma'   'sigma σ'
addPrefixedFunction 'symbols' 'Tau'     'Tau Τ'
addPrefixedFunction 'symbols' 'tau'     'tau τ'
addPrefixedFunction 'symbols' 'Upsilon' 'Upsilon Υ'
addPrefixedFunction 'symbols' 'upsilon' 'upsilon υ'
addPrefixedFunction 'symbols' 'Phi'     'Phi Φ'
addPrefixedFunction 'symbols' 'phi'     'phi φ'
addPrefixedFunction 'symbols' 'Chi'     'Chi Χ'
addPrefixedFunction 'symbols' 'chi'     'chi χ'
addPrefixedFunction 'symbols' 'Psi'     'Psi Ψ'
addPrefixedFunction 'symbols' 'psi'     'psi ψ'
addPrefixedFunction 'symbols' 'Omega'   'Omega Ω'
addPrefixedFunction 'symbols' 'omega'   'omega ω'
symbols_Alpha() {   printf %s Α; }
symbols_alpha() {   printf %s α; }
symbols_Beta() {    printf %s Β; }
symbols_beta() {    printf %s β; }
symbols_Gamma() {   printf %s Γ; }
symbols_gamma() {   printf %s γ; }
symbols_Delta() {   printf %s Δ; }
symbols_delta() {   printf %s δ; }
symbols_Epsilon() { printf %s Ε; }
symbols_epsilon() { printf %s ε; }
symbols_Zeta() {    printf %s Ζ; }
symbols_zeta() {    printf %s ζ; }
symbols_Eta() {     printf %s Η; }
symbols_eta() {     printf %s η; }
symbols_Theta() {   printf %s Θ; }
symbols_theta() {   printf %s θ; }
symbols_Iota() {    printf %s Ι; }
symbols_iota() {    printf %s ι; }
symbols_Kappa() {   printf %s Κ; }
symbols_kappa() {   printf %s κ; }
symbols_Lambda() {  printf %s Λ; }
symbols_lambda() {  printf %s λ; }
symbols_Mu() {      printf %s Μ; }
symbols_mu() {      printf %s μ; }
symbols_Nu() {      printf %s Ν; }
symbols_nu() {      printf %s ν; }
symbols_Xi() {      printf %s Ξ; }
symbols_xi() {      printf %s ξ; }
symbols_Omicron() { printf %s Ο; }
symbols_omicron() { printf %s ο; }
symbols_Pi() {      printf %s Π; }
symbols_pi() {      printf %s π; }
symbols_Rho() {     printf %s Ρ; }
symbols_rho() {     printf %s ρ; }
symbols_Sigma() {   printf %s Σ; }
symbols_sigma() {   printf %s σ; }
symbols_Tau() {     printf %s Τ; }
symbols_tau() {     printf %s τ; }
symbols_Upsilon() { printf %s Υ; }
symbols_upsilon() { printf %s υ; }
symbols_Phi() {     printf %s Φ; }
symbols_phi() {     printf %s φ; }
symbols_Chi() {     printf %s Χ; }
symbols_chi() {     printf %s χ; }
symbols_Psi() {     printf %s Ψ; }
symbols_psi() {     printf %s ψ; }
symbols_Omega() {   printf %s Ω; }
symbols_omega() {   printf %s ω; }

