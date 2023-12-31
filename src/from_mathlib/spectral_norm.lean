/-
Copyright (c) 2023 María Inés de Frutos-Fernández. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: María Inés de Frutos-Fernández
-/
import ring_theory.polynomial.vieta
import from_mathlib.minpoly
import from_mathlib.normal_closure
import from_mathlib.alg_norm_of_galois

/-!
# The spectral norm and the norm extension theorem

We define the spectral value and the spectral norm. We prove the norm extension theorem
[BGR, Theorem 3.2.1/2] : given a nonarchimedean, multiplicative normed field `K` and an algebraic
extension `L/K`, the spectral norm is a power-multiplicative `K`-algebra norm on `L` extending
the norm on `K`. All `K`-algebra automorphisms of `L` are isometries with respect to this norm. 
If `L/K` is finite, we get a formula relating the spectral norm on `L` with any other
power-multiplicative norm on `L` extending the norm on `K`.

As a prerequisite, we formalize the proof of [BGR, Proposition 3.1.2/1].

## Main Definitions

* `spectral_value` : the spectral value of a polynomial in `R[X]`. 
* `spectral_norm` :The spectral norm `|y|_sp` is the spectral value of the minimal of `y` over `K`.
* `spectral_alg_norm` : the spectral norm is a `K`-algebra norm on `L`.

## Main Results

* `spectral_norm_ge_norm` : if `f` is a power-multiplicative `K`-algebra norm on `L` with `f 1 ≤ 1`,
  then `f` is bounded above by `spectral_norm K L`. 
* `spectral_norm_aut_isom` : the `K`-algebra automorphisms of `L` are isometries with respect to 
  the spectral norm.
* `spectral_norm_max_of_fd_normal` : iff `L/K` is finite and normal, then 
  `spectral_norm K L x = supr (λ (σ : L ≃ₐ[K] L), f (σ x))`. 
* `spectral_norm_is_pow_mul` : the spectral norm is power-multiplicative.
* `spectral_norm_is_nonarchimedean` : the spectral norm is nonarchimedean. 
* `spectral_norm_extends` : the spectral norm extends the norm on `K`.

## References
* [S. Bosch, U. Güntzer, R. Remmert, *Non-Archimedean Analysis*][bosch-guntzer-remmert]

## Tags

spectral, spectral norm, spectral value, seminorm, norm, nonarchimedean
-/


noncomputable theory

open polynomial multiset

open_locale polynomial

-- Auxiliary lemmas
section aux_lemmas

namespace list

variables {α : Type*} [linear_order α] 

lemma max_repeat {n : ℕ} (a : α) : foldr max a (repeat a n) = a :=
begin
  induction n with n hn,
  { simp only [list.repeat, list.foldr_nil] },
  { simp only [foldr, repeat, foldr_cons, max_eq_left_iff],
    exact le_of_eq hn, }
end

lemma le_max_of_exists_le {l : list α} {a x : α} (b : α) (hx : x ∈ l) (h : a ≤ x) : 
  a ≤ l.foldr max b :=
begin
  induction l with y l IH,
  { exact absurd hx (list.not_mem_nil _), },
  { obtain rfl | hl := hx,
    simp only [list.foldr, list.foldr_cons],
    { exact le_max_of_le_left h, },
    { exact le_max_of_le_right (IH hl) }}
end

end list

namespace polynomial

variables {K : Type*} [normed_field K] {L : Type*} [field L] [algebra K L] 

lemma nat_degree_pos_of_monic_of_root {p : K[X]} (hp : p.monic) {x : L} (hx : aeval x p = 0) : 
  0 < p.nat_degree := 
nat_degree_pos_of_aeval_root (ne_zero_of_ne_zero_of_monic one_ne_zero hp) hx
  ((injective_iff_map_eq_zero (algebra_map K L)).mp (algebra_map K L).injective)

lemma monic_of_prod (p : K[X]) {n : ℕ} (b : fin n → L) 
  (hp : map_alg K L p = finprod (λ (k : fin n), X - (C (b k)))) : p.monic :=
begin
  have hprod : (finprod (λ (k : fin n), X - C (b k))).monic,
  { rw finprod_eq_prod_of_fintype,
    exact monic_prod_of_monic _ _ (λ m hm, monic_X_sub_C (b m)) },
  rw [← hp, map_alg_eq_map] at hprod,
  exact monic_of_injective (algebra_map K L).injective hprod,
end

lemma monic_of_prod' (p : K[X]) (s : multiset L)
  (hp : map_alg K L p = (multiset.map (λ (a : L), X - C a) s).prod) : p.monic :=
begin
  have hprod : ((multiset.map (λ (a : L), X - C a) s).prod).monic,
  { exact monic_multiset_prod_of_monic _ _ (λ m hm, monic_X_sub_C m) },
  rw [← hp, map_alg_eq_map] at hprod,
  exact monic_of_injective (algebra_map K L).injective hprod,
end

lemma C_finset_add {α : Type*} (s : finset α) {K : Type*} [semiring K] (b : α → K) :
  s.sum (λ (x : α), C (b x)) = C (s.sum b) := 
begin
  classical,
  apply s.induction_on,
  { simp only [finset.sum_empty, _root_.map_zero] },
  { intros a s ha hs,
    rw [finset.sum_insert ha, finset.sum_insert ha, hs, C_add], }
end

lemma C_finset_prod {α : Type*} (s : finset α) {K : Type*} [comm_ring K] (b : α → K) :
  s.prod (λ (x : α), C (b x)) = C (s.prod  b) := 
begin
  classical,
  apply s.induction_on,
  { simp only [finset.prod_empty, map_one] },
  { intros a s ha hs,
    rw [finset.prod_insert ha, finset.prod_insert ha, hs, C_mul], }
end

lemma prod_X_add_C_nat_degree {L : Type*} [field L] {n : ℕ} (b : fin n → L) :
  (finset.univ.prod (λ (i : fin n), X - C (b i))).nat_degree = n :=
begin
  rw nat_degree_prod _ _ (λ m hm, X_sub_C_ne_zero (b m)),
  simp only [nat_degree_X_sub_C, finset.sum_const, finset.card_fin,
    algebra.id.smul_eq_mul, mul_one],
end

lemma aeval_root (s : multiset L) {x : L} (hx : x ∈ s) {p : K[X]}
  (hp : map_alg K L p = (multiset.map (λ (a : L), X - C a) s).prod) : aeval x p = 0 :=
begin
  have : aeval x (map_alg K L p) = aeval x p,
  { rw [map_alg_eq_map, aeval_map_algebra_map] },
  rw [← this, hp, coe_aeval_eq_eval],
  have hy : (X - C x) ∣ (multiset.map (λ (a : L), X - C a) s).prod,
  { apply multiset.dvd_prod,
    simp only [multiset.mem_map, sub_right_inj, C_inj, exists_eq_right],
    exact hx },
  rw eval_eq_zero_of_dvd_of_eval_eq_zero hy,
  simp only [eval_sub, eval_X, eval_C, sub_self],
end

end polynomial

namespace real 

lemma multiset_prod_le_pow_card {K L : Type*} [semi_normed_comm_ring K] [ring L] [algebra K L]
  {t : multiset L} {f : algebra_norm K L} {y : L} (hf : ∀ (x : ℝ), x ∈ multiset.map f t → x ≤ f y) : 
  (map f t).prod ≤ f y ^ card (map f t) := 
begin
  set g : L → nnreal := λ x : L, ⟨f x, map_nonneg _ _⟩,
  have hg_le : (map g t).prod ≤ g y ^ card (map g t),
  { apply prod_le_pow_card,
    intros x hx,
    obtain ⟨a, hat, hag⟩ := mem_map.mp hx,
    rw [subtype.ext_iff, subtype.coe_mk] at hag,
    rw [← nnreal.coe_le_coe, subtype.coe_mk],
    exact hf (x : ℝ) (mem_map.mpr ⟨a, hat, hag⟩), },
  rw ← nnreal.coe_le_coe at hg_le,
  convert hg_le,
  { simp only [nnreal.coe_multiset_prod, multiset.map_map, function.comp_app, subtype.coe_mk] },
  { simp only [card_map] }
end

lemma multiset_le_prod_of_submultiplicative {α : Type*} [comm_monoid α] {f : α → ℝ}
  (h_nonneg : ∀ a, 0 ≤ f a) (h_one : f 1 = 1) (h_mul : ∀ a b, f (a * b) ≤ f a * f b)
  (s : multiset α) : f s.prod ≤ (s.map f).prod := 
begin
  set g : α → nnreal := λ x : α, ⟨f x, h_nonneg _ ⟩,
  have hg_le : g s.prod ≤ (s.map g).prod,
  { apply multiset.le_prod_of_submultiplicative,
    { ext, rw [subtype.coe_mk, nonneg.coe_one, h_one], },
    { intros a b, 
      simp only [← nnreal.coe_le_coe, subtype.coe_mk, nonneg.mk_mul_mk],
      exact h_mul _ _, }},
  rw ← nnreal.coe_le_coe at hg_le,
  convert hg_le,
  simp only [nnreal.coe_multiset_prod, multiset.map_map, function.comp_app, subtype.coe_mk],
end

end real

namespace multiset

section decidable

variables {α : Type*} [decidable_eq α] 

lemma max (f : α → ℝ) {s : multiset α} (hs : s.to_finset.nonempty) :
  ∃ y : α, y ∈ s ∧ ∀ z : α, z ∈ s → f z ≤ f y := 
begin
  have hsf : (map f s).to_finset.nonempty,
  { obtain ⟨x, hx⟩ := hs.bex,
    exact ⟨f x, mem_to_finset.mpr (mem_map.mpr ⟨x, (mem_to_finset.mp hx), rfl⟩)⟩ },
  have h := (s.map f).to_finset.max'_mem hsf,
  rw [mem_to_finset, mem_map] at h,
  obtain ⟨y, hys, hymax⟩ := h,
  use [y, hys],
  intros z hz,
  rw hymax,
  exact finset.le_max' _ _ (mem_to_finset.mpr (mem_map.mpr ⟨z, hz, rfl⟩)),
end

lemma card_to_finset_pos {m : multiset α} (hm : 0 < m.card) : 0 < m.to_finset.card :=
begin
  obtain ⟨x, hx⟩ := card_pos_iff_exists_mem.mp hm,
  exact finset.card_pos.mpr ⟨x, mem_to_finset.mpr hx⟩,
end

end decidable

@[to_additive le_sum_of_subadditive_on_pred]
lemma le_prod_of_submultiplicative_on_pred'  {α β : Type*} [comm_monoid α] [ordered_comm_ring β] 
  (f : α → β) (p : α → Prop) (h_nonneg : ∀ a, 0 ≤ f a) (h_one : f 1 = 1) (hp_one : p 1)
  (h_mul : ∀ a b, p a → p b → f (a * b) ≤ f a * f b) (hp_mul : ∀ a b, p a → p b → p (a * b))
  (s : multiset α) (hps : ∀ a, a ∈ s → p a) :
  f s.prod ≤ (s.map f).prod :=
begin
  revert s,
  refine multiset.induction _ _,
  { simp [le_of_eq h_one] },
  intros a s hs hpsa,
  have hps : ∀ x, x ∈ s → p x, from λ x hx, hpsa x (mem_cons_of_mem hx),
  have hp_prod : p s.prod, from prod_induction p s hp_mul hp_one hps,
  rw [prod_cons, map_cons, prod_cons],
  refine (h_mul a s.prod (hpsa a (mem_cons_self a s)) hp_prod).trans _,
  exact mul_le_mul_of_nonneg_left (hs hps) (h_nonneg _),
end

@[to_additive le_sum_of_subadditive]
lemma le_prod_of_submultiplicative' {α β : Type*} [comm_monoid α] [ordered_comm_ring β]
  (f : α → β) (h_nonneg : ∀ a, 0 ≤ f a) (h_one : f 1 = 1) (h_mul : ∀ a b, f (a * b) ≤ f a * f b) 
  (s : multiset α) : f s.prod ≤ (s.map f).prod :=
le_prod_of_submultiplicative_on_pred' f (λ i, true) h_nonneg h_one trivial (λ x y _ _ , h_mul x y) 
  (by simp) s (by simp)

end multiset

namespace finset

lemma powerset_len_nonempty' {α : Type*} {n : ℕ} {s : finset α} (h : n ≤ s.card) :
  (finset.powerset_len n s).nonempty :=
begin
  classical,
  induction s using finset.induction_on with x s hx IH generalizing n,
  { rw [finset.card_empty, le_zero_iff] at h,
    rw [h, finset.powerset_len_zero],
    exact finset.singleton_nonempty _, },
  { cases n,
    { simp },
    { rw [finset.card_insert_of_not_mem hx, nat.succ_le_succ_iff] at h,
      rw finset.powerset_len_succ_insert hx,
      refine finset.nonempty.mono _ ((IH h).image (insert x)),
      convert (finset.subset_union_right _ _) }}
end

theorem le_prod_of_submultiplicative' {ι M N : Type*} [comm_monoid M] 
  [ordered_comm_ring N] (f : M → N) (h_nonneg : ∀ a, 0 ≤ f a) (h_one : f 1 = 1) 
  (h_mul : ∀ (x y : M), f (x * y) ≤ f x * f y) (s : finset ι) (g : ι → M) :
f (s.prod (λ (i : ι), g i)) ≤ s.prod (λ (i : ι), f (g i)) := 
begin
  refine le_trans (multiset.le_prod_of_submultiplicative' f h_nonneg h_one h_mul _) _,
  rw multiset.map_map,
  refl,
end

end finset

section is_nonarchimedean

variables {K L : Type*} [normed_comm_ring K] [comm_ring L] [algebra K L]

lemma is_nonarchimedean_finset_powerset_image_add {f : algebra_norm K L}
  (hf_na : is_nonarchimedean f) {n : ℕ} (b : fin n → L) (m : ℕ) :
  ∃ (s : (finset.powerset_len (fintype.card (fin n) - m) (@finset.univ (fin n) _))),
    f ((finset.powerset_len (fintype.card (fin n) - m) finset.univ).sum 
      (λ (t : finset (fin n)), t.prod (λ (i : fin n), -b i))) ≤
    f (s.val.prod (λ (i : fin n), -b i)) := 
begin
  set g := (λ (t : finset (fin n)), t.prod (λ (i : fin n), -b i)) with hg,
  obtain ⟨b, hb_in, hb⟩ := is_nonarchimedean_finset_image_add hf_na g 
    (finset.powerset_len (fintype.card (fin n) - m) finset.univ),
  have hb_ne : (finset.powerset_len (fintype.card (fin n) - m)
    (finset.univ : finset(fin n))).nonempty,
  { rw [fintype.card_fin],
    have hmn : n - m ≤ (finset.univ : finset (fin n)).card,
    { rw [finset.card_fin], 
      exact nat.sub_le n m },
    exact finset.powerset_len_nonempty' hmn, },
  use [⟨b, hb_in hb_ne⟩, hb],
end

lemma is_nonarchimedean_multiset_powerset_image_add {f : algebra_norm K L}
  (hf_na : is_nonarchimedean f) (s : multiset L) (m : ℕ) :
  ∃ t : multiset L, t.card = s.card - m ∧ (∀ x : L, x ∈ t → x ∈ s) ∧ 
    f (map multiset.prod (powerset_len (s.card - m) s)).sum ≤ f (t.prod) := 
begin
  set g := (λ (t : multiset L), t.prod) with hg,
  obtain ⟨b, hb_in, hb_le⟩ := is_nonarchimedean_multiset_image_add hf_na g
    (powerset_len (s.card - m) s),
  have hb : b ≤ s ∧ b.card = s.card - m,
  { rw [← multiset.mem_powerset_len],
    apply hb_in,
    rw [card_powerset_len],
    exact nat.choose_pos ((s.card).sub_le m), },
  refine ⟨b, hb.2, (λ x hx, multiset.mem_of_le hb.left hx), hb_le⟩,
end

end is_nonarchimedean

namespace intermediate_field

variables {K L : Type*} [field K] [field L] [algebra K L] (E : intermediate_field K L)

/- Auxiliary instances to avoid timeouts. -/
instance aux : is_scalar_tower K E E := infer_instance

instance aux' : is_scalar_tower K E (algebraic_closure E) := 
@algebraic_closure.is_scalar_tower E _ K E _ _ _ _ _ (intermediate_field.aux E)

instance : is_scalar_tower K E (normal_closure K ↥E (algebraic_closure ↥E)) := infer_instance

instance : normal K (algebraic_closure K) := 
normal_iff.mpr (λ x, ⟨is_algebraic_iff_is_integral.mp (algebraic_closure.is_algebraic K x), 
  is_alg_closed.splits_codomain (minpoly K x)⟩)

lemma is_algebraic (h_alg_L : algebra.is_algebraic K L) (E : intermediate_field K L) : 
  algebra.is_algebraic K E := λ y,
begin
  obtain ⟨p, hp0, hp⟩ := h_alg_L ↑y,
  rw [subalgebra.aeval_coe, subalgebra.coe_eq_zero] at hp,
  exact ⟨p, hp0, hp⟩,
end


lemma adjoin_simple.alg_closure_normal (h_alg : algebra.is_algebraic K L) (x : L) :
  normal K (algebraic_closure K⟮x⟯) := 
normal_iff.mpr (λ y, ⟨is_algebraic_iff_is_integral.mp (algebra.is_algebraic_trans 
  (is_algebraic h_alg K⟮x⟯) (algebraic_closure.is_algebraic K⟮x⟯) y),
  is_alg_closed.splits_codomain (minpoly K y)⟩)

lemma adjoin_double.alg_closure_normal (h_alg : algebra.is_algebraic K L) (x y : L) :
  normal K (algebraic_closure K⟮x, y⟯) := 
normal_iff.mpr (λ z, ⟨is_algebraic_iff_is_integral.mp (algebra.is_algebraic_trans 
  (is_algebraic h_alg K⟮x, y⟯) (algebraic_closure.is_algebraic K⟮x, y⟯) z),
  is_alg_closed.splits_codomain (minpoly K z)⟩)

lemma adjoin_adjoin.finite_dimensional {x y : L} (hx : is_integral K x) (hy : is_integral K y) :
  finite_dimensional K K⟮x, y⟯ := 
begin
  haveI hx_fd : finite_dimensional K K⟮x⟯ := adjoin.finite_dimensional hx,
  have hy' : is_integral K⟮x⟯ y := is_integral_of_is_scalar_tower hy,
  haveI hy_fd : finite_dimensional K⟮x⟯ K⟮x⟯⟮y⟯ := adjoin.finite_dimensional hy',
  rw ← adjoin_simple_adjoin_simple,
  apply finite_dimensional.trans K K⟮x⟯ K⟮x⟯⟮y⟯,
end

lemma mem_adjoin_adjoin_left (F : Type u_1) [field F] {E : Type u_2} [field E] [algebra F E]
  (x y : E) : x ∈ F⟮x, y⟯ := 
begin
  rw [← adjoin_simple_adjoin_simple, adjoin_simple_comm],
  exact subset_adjoin F⟮y⟯ {x} (set.mem_singleton x),
end

lemma mem_adjoin_adjoin_right (F : Type u_1) [field F] {E : Type u_2} [field E] [algebra F E]
  (x y : E) : y ∈ F⟮x, y⟯ :=
by rw ← adjoin_simple_adjoin_simple; exact subset_adjoin F⟮x⟯ {y} (set.mem_singleton y)

/-- The first generator of an intermediate field of the form `F⟮x, y⟯`. -/
def adjoin_adjoin.gen_1 (F : Type u_1) [field F] {E : Type u_2} [field E] [algebra F E] (x y : E) :
  F⟮x, y⟯ := 
⟨x, mem_adjoin_adjoin_left F x y⟩

/-- The second generator of an intermediate field of the form `F⟮x, y⟯`. -/
def adjoin_adjoin.gen_2 (F : Type u_1) [field F] {E : Type u_2} [field E] [algebra F E] (x y : E) :
  F⟮x, y⟯ :=
⟨y, mem_adjoin_adjoin_right F x y⟩

@[simp] theorem adjoin_adjoin.algebra_map_gen_1 (F : Type u_1) [field F] {E : Type u_2}
  [field E] [algebra F E] (x y : E) : 
  (algebra_map ↥F⟮x, y⟯ E) (intermediate_field.adjoin_adjoin.gen_1 F x y) = x := rfl

@[simp] theorem adjoin_adjoin.algebra_map_gen_2 (F : Type u_1) [field F] {E : Type u_2}
  [field E] [algebra F E] (x y : E) : 
  (algebra_map ↥F⟮x, y⟯ E) (intermediate_field.adjoin_adjoin.gen_2 F x y) = y := rfl

end intermediate_field

section

variables {K L : Type*} [normed_field K] [ring L] [algebra K L]

lemma extends_is_norm_le_one_class {f : L → ℝ} (hf_ext : function_extends (norm : K → ℝ) f) : 
  f 1 ≤ 1 := 
by rw [← (algebra_map K L).map_one, hf_ext, norm_one]

lemma extends_is_norm_one_class {f : L → ℝ} (hf_ext : function_extends (norm : K → ℝ) f) :
  f 1 = 1 := 
by rw [← (algebra_map K L).map_one, hf_ext, norm_one]


end

end aux_lemmas

variables {R : Type*}

section spectral_value

section seminormed

variables [semi_normed_ring R]

/-- The function `ℕ → ℝ` sending `n` to `‖ p.coeff n ‖^(1/(p.nat_degree - n : ℝ))`, if 
  `n < p.nat_degree`, or to `0` otherwise. -/
def spectral_value_terms (p : R[X]) : ℕ → ℝ := 
λ (n : ℕ), if n < p.nat_degree then ‖ p.coeff n ‖^(1/(p.nat_degree - n : ℝ)) else 0 

lemma spectral_value_terms_of_lt_nat_degree (p : R[X]) {n : ℕ} 
  (hn : n < p.nat_degree ) : spectral_value_terms p n = ‖ p.coeff n ‖^(1/(p.nat_degree - n : ℝ)) := 
by simp only [spectral_value_terms, if_pos hn]

lemma spectral_value_terms_of_nat_degree_le (p : R[X]) {n : ℕ}
  (hn : p.nat_degree ≤ n) : spectral_value_terms p n = 0 := 
by simp only [spectral_value_terms, if_neg (not_lt.mpr hn)] 

/-- The spectral value of a polynomial in `R[X]`. -/
def spectral_value (p : R[X]) : ℝ := supr (spectral_value_terms p)

/-- The sequence `spectral_value_terms p` is bounded above. -/
lemma spectral_value_terms_bdd_above (p : R[X]) :
  bdd_above (set.range (spectral_value_terms p)) := 
begin
  use list.foldr max 0
  (list.map (λ n, ‖ p.coeff n ‖^(1/(p.nat_degree - n : ℝ))) (list.range p.nat_degree)),
  { rw mem_upper_bounds,
    intros r hr,
    obtain ⟨n, hn⟩ := set.mem_range.mpr hr,
    simp only [spectral_value_terms] at hn,
    split_ifs at hn with hd hd,
    { have h : ‖ p.coeff n ‖ ^ (1 / (p.nat_degree - n : ℝ)) ∈ list.map 
        (λ (n : ℕ), ‖ p.coeff n ‖ ^ (1 / (p.nat_degree - n : ℝ))) (list.range p.nat_degree),
      { simp only [list.mem_map, list.mem_range],
        exact ⟨n, hd, rfl⟩, },
    exact list.le_max_of_exists_le 0 h (ge_of_eq hn), },
    { rw ← hn,
      by_cases hd0 : p.nat_degree = 0,
      { rw [hd0, list.range_zero, list.map_nil, list.foldr_nil], },
      { have h : ‖ p.coeff 0 ‖ ^ (1 / (p.nat_degree - 0 : ℝ)) ∈ list.map 
          (λ (n : ℕ), ‖ p.coeff n ‖ ^ (1 / (p.nat_degree - n : ℝ))) (list.range p.nat_degree),
        { simp only [list.mem_map, list.mem_range],
          exact ⟨0, nat.pos_of_ne_zero hd0, by rw nat.cast_zero⟩,},
      refine list.le_max_of_exists_le 0 h _,
      exact real.rpow_nonneg_of_nonneg (norm_nonneg _) _}}},
end

/-- The range of `spectral_value_terms p` is a finite set. -/
lemma spectral_value_terms_finite_range (p : R[X]) :
  (set.range (spectral_value_terms p)).finite :=
begin
  have h_ss : set.range (spectral_value_terms p) ⊆ set.range (λ (n : fin p.nat_degree), 
    ‖ p.coeff n ‖^(1/(p.nat_degree - n : ℝ))) ∪ {(0 : ℝ)},
  { intros x hx,
    obtain ⟨m, hm⟩ := set.mem_range.mpr hx,
    by_cases hm_lt : m < p.nat_degree,
    { simp only [spectral_value_terms_of_lt_nat_degree p hm_lt] at hm,
      rw ← hm,
      exact set.mem_union_left _ ⟨⟨m, hm_lt⟩, rfl⟩, },
    { simp only [spectral_value_terms_of_nat_degree_le p (le_of_not_lt hm_lt)] at hm,
      rw hm,
      exact set.mem_union_right _ (set.mem_singleton _), }},
  exact set.finite.subset (set.finite.union (set.finite_range _) (set.finite_singleton _)) h_ss,
end

/-- The sequence `spectral_value_terms p` is nonnegative. -/
lemma spectral_value_terms_nonneg (p : R[X]) (n : ℕ) : 0 ≤ spectral_value_terms p n :=
begin
  simp only [spectral_value_terms],
  split_ifs with h,
  { exact real.rpow_nonneg_of_nonneg (norm_nonneg _) _ },
  { exact le_refl _ },
end

/-- The spectral value of a polyomial is nonnegative. -/
lemma spectral_value_nonneg (p : R[X]) :
  0 ≤ spectral_value p :=
real.supr_nonneg (spectral_value_terms_nonneg p)

variable [nontrivial R]

/-- The polynomial `X - r` has spectral value `‖ r ‖`. -/
lemma spectral_value_X_sub_C (r : R) : spectral_value (X - C r) = ‖ r ‖ := 
begin
  rw spectral_value, rw spectral_value_terms,
  simp only [nat_degree_X_sub_C, nat.lt_one_iff, coeff_sub,
    nat.cast_one, one_div],
  suffices : (⨆ (n : ℕ), ite (n = 0) ‖ r ‖  0) = ‖ r ‖,
  { rw ← this,
    apply congr_arg,
    ext n,
    by_cases hn : n = 0,
    { rw [if_pos hn, if_pos hn, hn, nat.cast_zero, sub_zero, coeff_X_zero,
        coeff_C_zero, zero_sub, norm_neg, inv_one, real.rpow_one] },
    { rw [if_neg hn, if_neg hn], }},
  { apply csupr_eq_of_forall_le_of_forall_lt_exists_gt,
    { intro n,
      split_ifs,
      exact le_refl _, 
      exact norm_nonneg _ },
    { intros x hx, use 0,
      simp only [eq_self_iff_true, if_true, hx], }}
end

/-- The polynomial `X^n` has spectral value `0`. -/
lemma spectral_value_X_pow (n : ℕ) :
  spectral_value (X^n : R[X]) = 0 := 
begin
  rw spectral_value, rw spectral_value_terms,
  simp_rw [coeff_X_pow n, nat_degree_X_pow],
  convert csupr_const,
  ext m,
  by_cases hmn : m < n,
  { rw [if_pos hmn, real.rpow_eq_zero_iff_of_nonneg (norm_nonneg _), if_neg (ne_of_lt hmn),
      norm_zero, one_div, ne.def, inv_eq_zero, ← nat.cast_sub (le_of_lt hmn), nat.cast_eq_zero,
      nat.sub_eq_zero_iff_le],
    exact ⟨eq.refl _, not_le_of_lt hmn⟩ },
  { rw if_neg hmn },
  apply_instance, 
end

end seminormed

section normed

variables [normed_ring R] 

/-- The spectral value of `p` equals zero if and only if `p` is of the form `X^n`. -/
lemma spectral_value_eq_zero_iff [nontrivial R] {p : R[X]} (hp : p.monic) :
  spectral_value p = 0 ↔ p = X^p.nat_degree := 
begin
  refine ⟨λ h, _, λ h, _⟩,
  { rw spectral_value at h,
    ext,
    rw coeff_X_pow,
    by_cases hn : n = p.nat_degree,
    { rw [if_pos hn, hn, coeff_nat_degree], exact hp, },
    { rw if_neg hn,
      { by_cases hn' : n < p.nat_degree,
        { have h_le : supr (spectral_value_terms p) ≤ 0 := le_of_eq h,
          have h_exp : 0 < 1 / ((p.nat_degree : ℝ) - n),
          { rw [one_div_pos, ← nat.cast_sub (le_of_lt hn'), nat.cast_pos],
            exact nat.sub_pos_of_lt hn', },
          have h0 : (0 : ℝ) = 0^(1 / ((p.nat_degree : ℝ) - n)),
          { rw real.zero_rpow (ne_of_gt h_exp), },
          rw [supr, cSup_le_iff (spectral_value_terms_bdd_above p)
            (set.range_nonempty _)] at h_le,
          specialize h_le (spectral_value_terms p n) ⟨n, rfl⟩,
          simp only [spectral_value_terms, if_pos hn'] at h_le,
          rw [h0, real.rpow_le_rpow_iff (norm_nonneg _) (le_refl _) h_exp] at h_le,
          exact norm_eq_zero.mp (le_antisymm h_le (norm_nonneg _)) },
        { exact coeff_eq_zero_of_nat_degree_lt 
            (lt_of_le_of_ne (le_of_not_lt hn') (ne_comm.mpr hn)) }}}},
  { convert spectral_value_X_pow p.nat_degree,
    apply_instance }
end

end normed

end spectral_value

/- In this section we prove Proposition 3.1.2/1 from BGR. -/
section bdd_by_spectral_value

variables {K : Type*} [normed_field K] {L : Type*} [field L] [algebra K L]

/-- Part (1): the norm of any root of p is bounded by the spectral value of p. -/
lemma root_norm_le_spectral_value {f : algebra_norm K L}
  (hf_pm : is_pow_mul f) (hf_na : is_nonarchimedean f) (hf1 : f 1 ≤ 1)
  {p : K[X]} (hp : p.monic) {x : L} (hx : aeval x p = 0) : f x ≤ spectral_value p := 
begin
  by_cases hx0 : f x = 0,
  { rw hx0, exact spectral_value_nonneg p, },
  { by_contra' h_ge,
    have hn_lt : ∀ (n : ℕ) (hn : n < p.nat_degree), ‖ p.coeff n ‖ < (f x)^ (p.nat_degree - n),
    { intros n hn,
      have hexp : (‖p.coeff n ‖^(1/(p.nat_degree - n : ℝ)))^(p.nat_degree - n) = ‖ p.coeff n ‖,
      { rw [← real.rpow_nat_cast, ← real.rpow_mul (norm_nonneg _), mul_comm, 
          real.rpow_mul (norm_nonneg _), real.rpow_nat_cast, ← nat.cast_sub (le_of_lt hn), one_div,
          real.pow_nat_rpow_nat_inv (norm_nonneg _) (ne_of_gt (tsub_pos_of_lt hn))], },
      have h_base : ‖ p.coeff n ‖^(1/(p.nat_degree - n : ℝ)) < f x,
      { rw [spectral_value, supr, set.finite.cSup_lt_iff (spectral_value_terms_finite_range p)
          (set.range_nonempty (spectral_value_terms p))] at h_ge,
        have h_rg : ‖ p.coeff n ‖^ (1 / (p.nat_degree - n : ℝ)) ∈
          set.range (spectral_value_terms p),
        { use n, simp only [spectral_value_terms, if_pos hn] },
        exact h_ge (‖ p.coeff n ‖₊ ^ (1 / (↑(p.nat_degree) - ↑n))) h_rg },
      rw [← hexp, ← real.rpow_nat_cast, ← real.rpow_nat_cast],
      exact real.rpow_lt_rpow (real.rpow_nonneg_of_nonneg (norm_nonneg _) _) h_base 
        (nat.cast_pos.mpr (tsub_pos_of_lt hn)) },
    have h_deg : 0 < p.nat_degree := polynomial.nat_degree_pos_of_monic_of_root hp hx,
    have : ‖ (1 : K) ‖ = 1 := norm_one,
    have h_lt : f ((finset.range (p.nat_degree)).sum (λ (i : ℕ), p.coeff i • x ^ i)) < 
      f (x^(p.nat_degree)),
    { have hn' : ∀ (n : ℕ) (hn : n < p.nat_degree), f (p.coeff n • x ^ n) < f (x^(p.nat_degree)),
      { intros n hn,
        by_cases hn0 : n = 0,
        { rw [hn0, pow_zero, map_smul_eq_mul, hf_pm _ (nat.succ_le_iff.mpr h_deg),
            ← nat.sub_zero p.nat_degree, ← hn0],
          exact mul_lt_of_lt_of_le_one_of_nonneg (hn_lt n hn) hf1 (norm_nonneg _) },
        { have : p.nat_degree = (p.nat_degree - n) + n,
          { rw nat.sub_add_cancel (le_of_lt hn), },
          rw [map_smul_eq_mul, hf_pm _ (nat.succ_le_iff.mp (pos_iff_ne_zero.mpr hn0)), 
            hf_pm _ (nat.succ_le_iff.mpr h_deg), this, pow_add],
          exact (mul_lt_mul_right (pow_pos (lt_of_le_of_ne (map_nonneg _ _) (ne.symm hx0)) _)).mpr
            (hn_lt n hn), }},
      obtain ⟨m, hm_in, hm⟩ := is_nonarchimedean_finset_range_add_le hf_na p.nat_degree 
        (λ (i : ℕ), p.coeff i • x ^ i),
      exact lt_of_le_of_lt hm (hn' m (hm_in h_deg))  },
    have h0 : f 0 ≠ 0,
    { have h_eq : f 0 = f (x^(p.nat_degree)),
      { rw [← hx, aeval_eq_sum_range, finset.sum_range_succ, add_comm, hp.coeff_nat_degree,
        one_smul, ← max_eq_left_of_lt h_lt], 
        exact is_nonarchimedean_add_eq_max_of_ne hf_na (ne_of_lt h_lt) },
      rw h_eq,
      exact ne_of_gt (lt_of_le_of_lt (map_nonneg _ _) h_lt) },
    exact h0 (map_zero _), } 
end

open_locale classical

open multiset

/-- Part (2): if p splits into linear factors over B, then its spectral value equals the maximum
  of the norms of its roots. -/
lemma max_root_norm_eq_spectral_value {f : algebra_norm K L} (hf_pm : is_pow_mul f)
  (hf_na : is_nonarchimedean f) (hf1 : f 1 = 1) (p : K[X]) {n : ℕ} (hn : 0 < n) (b : fin n → L)
  (hp : map_alg K L p = finprod (λ (k : fin n), X - (C (b k)))) :
  supr (f ∘ b) = spectral_value p := 
begin
  apply le_antisymm,
  { haveI : nonempty (fin n) := fin.pos_iff_nonempty.mp hn,
    apply csupr_le,
    rintros m,
    have hm : aeval (b m) p = 0,
    { have hm' : aeval (b m) ((map_alg K L) p) = 0,
      { have hd1 : (aeval (b m)) (X - C (b m)) = 0,
        { rw [coe_aeval_eq_eval, eval_sub, eval_X,
            eval_C, sub_self] },
        rw [hp, finprod_eq_prod_of_fintype, aeval_def, eval₂_finset_prod],
        exact finset.prod_eq_zero (finset.mem_univ m) hd1, },
      rw [map_alg_eq_map, aeval_map_algebra_map] at hm',
      exact hm', },
    rw function.comp_apply,
    exact root_norm_le_spectral_value hf_pm hf_na (le_of_eq hf1) (p.monic_of_prod b hp) hm },
  { haveI : nonempty (fin n) := fin.pos_iff_nonempty.mp hn,
    have h_supr : 0 ≤ supr (f ∘ b) := (real.supr_nonneg (λ x, map_nonneg f (b x))),
    apply csupr_le,
    intros m,
    by_cases hm : m < p.nat_degree,
    { rw spectral_value_terms_of_lt_nat_degree _ hm,
      have h : 0 < (p.nat_degree - m : ℝ),
      { rw [sub_pos, nat.cast_lt], exact hm },
      rw [← real.rpow_le_rpow_iff (real.rpow_nonneg_of_nonneg (norm_nonneg _) _) h_supr h, 
        ← real.rpow_mul (norm_nonneg _), one_div_mul_cancel (ne_of_gt h), real.rpow_one,
        ← nat.cast_sub (le_of_lt hm), real.rpow_nat_cast],
      have hpn : n = p.nat_degree,
      { rw [← nat_degree_map (algebra_map K L), ← map_alg_eq_map, hp,
          finprod_eq_prod_of_fintype, polynomial.prod_X_add_C_nat_degree] },
      have hc : ‖ p.coeff m ‖ = f (((map_alg K L) p).coeff m),
      { rw [← algebra_norm.extends_norm hf1, map_alg_eq_map, coeff_map] },
        rw [hc, hp, finprod_eq_prod_of_fintype],
        simp_rw [sub_eq_add_neg, ← C_neg, finset.prod_eq_multiset_prod, ← pi.neg_apply,
          ← map_map (λ x : L, X + C x) (-b)],
        have hm_le' : m ≤ card (map (-b) finset.univ.val),
        { have : card finset.univ.val = finset.card finset.univ := rfl,
          rw [card_map, this, finset.card_fin n, hpn],
          exact (le_of_lt hm) },
        rw prod_X_add_C_coeff _ hm_le',
      have : m < n,
      { rw hpn, exact hm },
      obtain ⟨s, hs⟩ := is_nonarchimedean_finset_powerset_image_add hf_na b m,
      rw finset.esymm_map_val,
      have h_card : card (map (-b) finset.univ.val) = fintype.card (fin n),
      { rw [card_map], refl, },
      rw h_card,
      apply le_trans hs,
      have  h_pr: f (s.val.prod (λ (i : fin n), -b i)) ≤ s.val.prod (λ (i : fin n), f(-b i)),
      { exact finset.le_prod_of_submultiplicative' f (map_nonneg _) hf1 (map_mul_le_mul _) _ _ },
      apply le_trans h_pr,
      have : s.val.prod (λ (i : fin n), f (-b i)) ≤ s.val.prod (λ (i : fin n), supr (f ∘ b)),
      { apply finset.prod_le_prod,
        { intros i hi, exact map_nonneg _ _, },
        { intros i hi, 
          rw map_neg_eq_map,
          exact le_csupr (set.finite.bdd_above (set.range (f ∘ b)).to_finite) _, }},
      apply le_trans this,
      apply le_of_eq,
      simp only [subtype.val_eq_coe, finset.prod_const],
      suffices h_card : (s : finset (fin n)).card = p.nat_degree - m,
      { rw h_card },
      have hs' := s.property,
      simp only [subtype.val_eq_coe, fintype.card_fin, finset.mem_powerset_len] at hs',
      rw [hs'.right, hpn], },
    rw spectral_value_terms_of_nat_degree_le _ (le_of_not_lt hm),
    exact h_supr, }, 
end

/-- If `f` is a nonarchimedean, power-multiplicative `K`-algebra norm on `L`, then the spectral
  value of a polynomial `p : K[X]` that decomposes into linear factos in `L` is equal to the
  maximum of the norms of the roots. -/
lemma max_root_norm_eq_spectral_value' {f : algebra_norm K L} (hf_pm : is_pow_mul f)
  (hf_na : is_nonarchimedean f) (hf1 : f 1 = 1) (p : K[X]) (s : multiset L) 
  (hp : map_alg K L p = (map (λ (a : L), X - C a) s).prod) :
  supr (λ x : L, if x ∈ s then f x else 0 ) = spectral_value p :=
begin
  have h_le : 0 ≤ ⨆ (x : L), ite (x ∈ s) (f x) 0,
  { apply real.supr_nonneg,
    intro x,
    split_ifs,
    exacts [map_nonneg _ _, le_refl _] },
   apply le_antisymm,
  { apply csupr_le,
    rintros x,
    by_cases hx : x ∈ s,
    { have hx0 : aeval x p = 0 := polynomial.aeval_root s hx hp,
      rw if_pos hx,
      exact root_norm_le_spectral_value hf_pm hf_na (le_of_eq hf1) (p.monic_of_prod' s hp) hx0 },
    { rw if_neg hx,
      exact spectral_value_nonneg _, }},
  { apply csupr_le,
    intros m,
    by_cases hm : m < p.nat_degree,
    { rw spectral_value_terms_of_lt_nat_degree _ hm,
      have h : 0 < (p.nat_degree - m : ℝ),
      { rw [sub_pos, nat.cast_lt], exact hm },
      rw [← real.rpow_le_rpow_iff (real.rpow_nonneg_of_nonneg (norm_nonneg _) _) h_le h,
        ← real.rpow_mul (norm_nonneg _), one_div_mul_cancel (ne_of_gt h),
        real.rpow_one, ← nat.cast_sub (le_of_lt hm), real.rpow_nat_cast],
      have hps : s.card = p.nat_degree,
      { rw [← nat_degree_map (algebra_map K L), ← map_alg_eq_map, hp, 
          nat_degree_multiset_prod_X_sub_C_eq_card], },
      have hc : ‖ p.coeff m ‖ = f (((map_alg K L) p).coeff m),
      { rw [← algebra_norm.extends_norm hf1, map_alg_eq_map, coeff_map] },
      rw [hc, hp],
      have hm_le' : m ≤ s.card,
      { rw hps, exact le_of_lt hm, },
      rw prod_X_sub_C_coeff s hm_le',
      have h : f ((-1) ^ (s.card - m) * s.esymm (s.card - m)) = f (s.esymm (s.card - m)),
      { cases (neg_one_pow_eq_or L (s.card - m)) with h1 hn1,
        { rw [h1, one_mul] },
        { rw [hn1, neg_mul, one_mul, map_neg_eq_map], }},
      rw [h, multiset.esymm],
      have ht : ∃ t : multiset L, t.card = s.card - m ∧ (∀ x : L, x ∈ t → x ∈ s) ∧ 
      f (map multiset.prod (powerset_len (s.card - m) s)).sum ≤ f (t.prod),
      { have hm' : m < card s,
        { rw hps, exact hm, },
        exact is_nonarchimedean_multiset_powerset_image_add hf_na s m },
      obtain ⟨t, ht_card, hts, ht_ge⟩ := ht,
      apply le_trans ht_ge,
      have  h_pr: f (t.prod) ≤ (t.map f).prod,
      { exact real.multiset_le_prod_of_submultiplicative (map_nonneg _) hf1 (map_mul_le_mul _) _ },
      apply le_trans h_pr,
      have hs_ne : s.to_finset.nonempty,
      { rw [← finset.card_pos],
        apply card_to_finset_pos,
        rw hps,
        exact lt_of_le_of_lt (zero_le _) hm, },
      have hy : ∃ y : L, y ∈ s ∧ ∀ z : L, z ∈ s → f z ≤ f y := multiset.max f hs_ne,
      obtain ⟨y, hyx, hy_max⟩ := hy,
      have : (map f t).prod ≤ (f y) ^ (p.nat_degree - m),
      { have h_card : (p.nat_degree - m) = (t.map f).card,
        { rw [card_map, ht_card, ← hps] },
        have hx_le : ∀ (x : ℝ), x ∈ map f t → x ≤ f y,
        { intros r hr,
          obtain ⟨z, hzt, hzr⟩ := multiset.mem_map.mp hr,
          rw ← hzr,
          exact hy_max _ (hts _ hzt) },
        rw h_card,
        exact real.multiset_prod_le_pow_card hx_le, },
      have h_bdd : bdd_above (set.range (λ (x : L), ite (x ∈ s) (f x) 0)),
      { use f y,
        rw mem_upper_bounds,
        intros r hr,
        obtain ⟨z, hz⟩ := set.mem_range.mpr hr,
        simp only at hz,
        rw ← hz,
        split_ifs with h,
        { exact hy_max _ h },
        { exact map_nonneg _ _ }},
      apply le_trans this,
      apply pow_le_pow_of_le_left (map_nonneg _ _),
      apply le_trans _ (le_csupr h_bdd y),
      rw if_pos hyx, },
    { simp only [spectral_value_terms],
      rw if_neg hm,
      exact h_le }},
end

end bdd_by_spectral_value

section alg_equiv

variables {S A B C: Type*} [comm_semiring S] [semiring A] [semiring B] [semiring C] [algebra S A]
  [algebra S B] [algebra S C]

/-- The algebra equivalence obtained by composing two algebra equivalences. -/
def alg_equiv.comp (f : A ≃ₐ[S] B) (g : B ≃ₐ[S] C) : A ≃ₐ[S] C :=
{ to_fun    := g.to_fun ∘ f.to_fun,
  inv_fun   := f.inv_fun ∘ g.inv_fun,
  left_inv  :=  λ x, by simp only [alg_equiv.inv_fun_eq_symm, alg_equiv.to_fun_eq_coe,
    function.comp_app, alg_equiv.symm_apply_apply],
  right_inv := λ x, by simp only [alg_equiv.to_fun_eq_coe, alg_equiv.inv_fun_eq_symm,
    function.comp_app, alg_equiv.apply_symm_apply],
  map_mul'  := λ x y, by simp only [alg_equiv.to_fun_eq_coe, function.comp_app, map_mul],
  map_add'  := λ x y, by simp only [alg_equiv.to_fun_eq_coe, function.comp_app, _root_.map_add],
  commutes' := λ x, by simp only [alg_equiv.to_fun_eq_coe, function.comp_app, alg_equiv.commutes] }

lemma alg_equiv.comp_apply (f : A ≃ₐ[S] B) (g : B ≃ₐ[S] C) (x : A) : f.comp g x = g (f x) := rfl

end alg_equiv

/- In this section we prove Theorem 3.2.1/2 from BGR. -/

section spectral_norm

variables (K : Type*) [normed_field K] (L : Type*) [field L] [algebra K L]

/-- The spectral norm `|y|_sp` is the spectral value of the minimal of `y` over `K`. -/
def spectral_norm (y : L) : ℝ := spectral_value (minpoly K y)

variables {K L}
 
/-- If `L/E/K` is a tower of fields, then the spectral norm of `x : E` equals its spectral norm
  when regarded as an element of `L`. -/
lemma spectral_value.eq_of_tower {E : Type*} [field E] [algebra K E] [algebra E L]
  [is_scalar_tower K E L] (h_alg_E : algebra.is_algebraic K E) (x : E) :
  spectral_norm K E x = spectral_norm K L (algebra_map E L x) :=
begin
  have hx : minpoly K x = minpoly K  (algebra_map E L x),
  { exact minpoly.eq_of_algebra_map_eq (algebra_map E L).injective 
      (is_algebraic_iff_is_integral.mp (h_alg_E x)) rfl, },
  simp only [spectral_norm, hx],
end

variable (E : intermediate_field K L)

/-- If `L/E/K` is a tower of fields, then the spectral norm of `x : E` when regarded as an element 
  of the normal closure of `E` equals its spectral norm when regarded as an element of `L`. -/
lemma spectral_value.eq_normal (h_alg_L : algebra.is_algebraic K L) (x : E) : 
  spectral_norm K (normal_closure K E (algebraic_closure E))
    (algebra_map E (normal_closure K E (algebraic_closure E)) x) = 
  spectral_norm K L (algebra_map E L x) :=
begin
  simp only [spectral_norm, spectral_value],
  have h_min : minpoly K (algebra_map ↥E ↥(normal_closure K ↥E (algebraic_closure ↥E)) x) = 
    minpoly K (algebra_map ↥E L x),
  { have hx : is_integral K x := 
    is_algebraic_iff_is_integral.mp (intermediate_field.is_algebraic_iff.mpr (h_alg_L ↑x)),
    rw [← minpoly.eq_of_algebra_map_eq 
      ((algebra_map ↥E ↥(normal_closure K E (algebraic_closure E))).injective) hx rfl,
      minpoly.eq_of_algebra_map_eq (algebra_map ↥E L).injective hx rfl] },
  simp_rw h_min,
end

variable (y : L)

/-- `spectral_norm K L (0 : L) = 0`. -/
lemma spectral_norm_zero : spectral_norm K L (0 : L) = 0 := 
begin
  have h_lr: list.range 1 = [0] := rfl,
  rw [spectral_norm, spectral_value, spectral_value_terms, minpoly.zero, nat_degree_X],
  convert csupr_const,
  ext m,
  by_cases hm : m < 1,
  { rw [if_pos hm, nat.lt_one_iff.mp hm, nat.cast_one, nat.cast_zero, sub_zero,
      div_one, real.rpow_one, coeff_X_zero, norm_zero] },
  { rw if_neg hm },
  apply_instance,
end

/-- `spectral_norm K L y` is nonnegative. -/
lemma spectral_norm_nonneg (y : L) : 0 ≤  spectral_norm K L y := 
le_csupr_of_le (spectral_value_terms_bdd_above (minpoly K y)) 0 (spectral_value_terms_nonneg _ 0)

/-- `spectral_norm K L y` is positive if `y ≠ 0`. -/
lemma spectral_norm_zero_lt (h_alg : algebra.is_algebraic K L) {y : L} (hy : y ≠ 0) :
  0 < spectral_norm K L y := 
begin
  rw lt_iff_le_and_ne,
  refine ⟨spectral_norm_nonneg _, _⟩,
  rw [spectral_norm, ne.def, eq_comm, spectral_value_eq_zero_iff
    (minpoly.monic ((is_algebraic_iff_is_integral).mp (h_alg y)))],
  have h0 : coeff (minpoly K y) 0 ≠ 0  :=
  minpoly.coeff_zero_ne_zero (is_algebraic_iff_is_integral.mp (h_alg y)) hy,
  intro h,
  have h0' : (minpoly K y).coeff 0 = 0,
  { rw [h, coeff_X_pow,
      if_neg (ne_of_lt ( minpoly.nat_degree_pos (is_algebraic_iff_is_integral.mp (h_alg y))))] },
  exact h0 h0',
end

/-- If `spectral_norm K L x = 0`, then `x = 0`. -/
lemma eq_zero_of_map_spectral_norm_eq_zero (h_alg : algebra.is_algebraic K L) {x : L}
  (hx : spectral_norm K L x = 0) : x = 0 :=
begin
  by_contra h0,
  exact (ne_of_gt (spectral_norm_zero_lt h_alg h0)) hx,
end

/-- If `f` is a power-multiplicative `K`-algebra norm on `L` with `f 1 ≤ 1`, then `f`
  is bounded above by `spectral_norm K L`. -/
lemma spectral_norm_ge_norm (h_alg : algebra.is_algebraic K L) {f : algebra_norm K L}
  (hf_pm : is_pow_mul f) (hf_na : is_nonarchimedean f) (hf1 : f 1 ≤ 1) (x : L) : 
  f x ≤ spectral_norm K L x :=
begin
  apply root_norm_le_spectral_value hf_pm hf_na hf1
    (minpoly.monic ((is_algebraic_iff_is_integral).mp (h_alg x))),
  rw [minpoly.aeval],
end

/-- The `K`-algebra automorphisms of `L` are isometries with respect to the spectral norm. -/
lemma spectral_norm_aut_isom (h_alg : algebra.is_algebraic K L) (σ : L ≃ₐ[K] L) (x : L) : 
  spectral_norm K L x = spectral_norm K L (σ x) :=
by simp only [spectral_norm, minpoly.eq_of_conj h_alg]

-- We first assume that the extension is finite and normal
section finite

section normal

/-- If `L/K` is finite and normal, then `spectral_norm K L x = supr (λ (σ : L ≃ₐ[K] L), f (σ x))`. -/
lemma spectral_norm_max_of_fd_normal (h_alg : algebra.is_algebraic K L)
  (h_fin : finite_dimensional K L) (hn : normal K L) 
  {f : algebra_norm K L} (hf_pm : is_pow_mul f) (hf_na : is_nonarchimedean f)
  (hf_ext : function_extends (λ x : K, ‖ x ‖₊) f) (x : L) :
  spectral_norm K L x = supr (λ (σ : L ≃ₐ[K] L), f (σ x)) :=
begin
  refine le_antisymm _ (csupr_le (λ σ, root_norm_le_spectral_value hf_pm hf_na
    (extends_is_norm_le_one_class hf_ext) (minpoly.monic (normal.is_integral hn x))
    (minpoly.aeval_conj _ _))),
  { set p := minpoly K x with hp_def,
    have hp_sp : splits (algebra_map K L) (minpoly K x) := hn.splits x,
    obtain ⟨s, hs⟩ := (splits_iff_exists_multiset _).mp hp_sp,
    have : map_alg K L p = map (algebra_map K L) p := rfl,
    have h_lc : (algebra_map K L) (minpoly K x).leading_coeff = 1,
    { have h1 : (minpoly K x).leading_coeff = 1,
      { rw ← monic, exact minpoly.monic (normal.is_integral hn x),},
      rw [h1, map_one] },
    rw [h_lc, map_one, one_mul] at hs,
    simp only [spectral_norm],
    rw ← max_root_norm_eq_spectral_value' hf_pm hf_na (extends_is_norm_one_class hf_ext) _ _ hs,
    apply csupr_le,
    intros y,
    split_ifs,
    { have hy : ∃ σ : L ≃ₐ[K] L, σ x = y,
      { exact minpoly.conj_of_root' h_alg hn (polynomial.aeval_root s h hs), },
      obtain ⟨σ, hσ⟩ := hy,
      rw ← hσ,
      exact le_csupr (fintype.bdd_above_range _) σ, },
    { exact real.supr_nonneg (λ σ, map_nonneg _ _) }},
end

/-- If `L/K` is finite and normal, then `spectral_norm K L = alg_norm_of_galois h_fin hna`. -/
lemma spectral_norm_eq_alg_norm_of_galois (h_alg : algebra.is_algebraic K L) 
  (h_fin : finite_dimensional K L) (hn : normal K L) (hna : is_nonarchimedean (norm : K → ℝ)) :
  spectral_norm K L = alg_norm_of_galois h_fin hna := 
begin
  ext x,
  set f := classical.some (finite_extension_pow_mul_seminorm h_fin hna) with hf,
  have hf_pow : is_pow_mul f :=
  (classical.some_spec (finite_extension_pow_mul_seminorm h_fin hna)).1,
  have hf_ext : function_extends _ f :=
  (classical.some_spec (finite_extension_pow_mul_seminorm h_fin hna)).2.1,
  have hf_na : is_nonarchimedean f :=
  (classical.some_spec (finite_extension_pow_mul_seminorm h_fin hna)).2.2,
  rw spectral_norm_max_of_fd_normal h_alg h_fin hn hf_pow hf_na hf_ext,
  refl,
end

/-- If `L/K` is finite and normal, then `spectral_norm K L` is power-multiplicative. -/
lemma spectral_norm_is_pow_mul_of_fd_normal (h_alg : algebra.is_algebraic K L)
  (h_fin : finite_dimensional K L) (hn : normal K L) 
  (hna : is_nonarchimedean (norm : K → ℝ)) : is_pow_mul (spectral_norm K L) :=
begin
  rw spectral_norm_eq_alg_norm_of_galois h_alg h_fin hn hna,
  exact alg_norm_of_galois_is_pow_mul h_fin hna,
end

/-- The spectral norm is a `K`-algebra norm on `L` when `L/K` is finite and normal. -/
def spectral_alg_norm_of_fd_normal (h_alg : algebra.is_algebraic K L)
  (h_fin : finite_dimensional K L) (hn : normal K L) (hna : is_nonarchimedean (norm : K → ℝ)) :
  algebra_norm K L :=
{ to_fun    := spectral_norm K L,
  map_zero' := by {rw spectral_norm_eq_alg_norm_of_galois h_alg h_fin hn hna, exact map_zero _ },
  add_le'   := by {rw spectral_norm_eq_alg_norm_of_galois h_alg h_fin hn hna, exact map_add_le_add _ },
  neg'      := by {rw spectral_norm_eq_alg_norm_of_galois h_alg h_fin hn hna, exact map_neg_eq_map _ },
  mul_le'   := by {rw spectral_norm_eq_alg_norm_of_galois h_alg h_fin hn hna, exact map_mul_le_mul _ },
  eq_zero_of_map_eq_zero' := λ x,
  by {rw spectral_norm_eq_alg_norm_of_galois h_alg h_fin hn hna, exact eq_zero_of_map_eq_zero _ },
  smul'     := 
  by { rw spectral_norm_eq_alg_norm_of_galois h_alg h_fin hn hna, 
       exact algebra_norm_class.map_smul_eq_mul _  }}

lemma spectral_alg_norm_of_fd_normal_def (h_alg : algebra.is_algebraic K L) 
  (h_fin : finite_dimensional K L) (hn : normal K L)  (hna : is_nonarchimedean (norm : K → ℝ)) (x : L) : 
  spectral_alg_norm_of_fd_normal h_alg h_fin hn hna x = spectral_norm K L x := 
rfl

/-- The spectral norm is nonarchimedean when `L/K` is finite and normal. -/
lemma spectral_norm_is_nonarchimedean_of_fd_normal (h_alg : algebra.is_algebraic K L)
  (h_fin : finite_dimensional K L) (hn : normal K L) (hna : is_nonarchimedean (norm : K → ℝ))  :
  is_nonarchimedean (spectral_norm K L) :=
begin
  rw spectral_norm_eq_alg_norm_of_galois h_alg h_fin hn hna,
  exact alg_norm_of_galois_is_nonarchimedean h_fin hna,
end

/-- The spectral norm extends the norm on `K` when `L/K` is finite and normal. -/
lemma spectral_norm_extends_norm_of_fd (h_alg : algebra.is_algebraic K L)
  (h_fin : finite_dimensional K L) (hn : normal K L)  (hna : is_nonarchimedean (norm : K → ℝ)) :
  function_extends (norm : K → ℝ) (spectral_norm K L) :=
begin
  rw spectral_norm_eq_alg_norm_of_galois h_alg h_fin hn hna,
  exact alg_norm_of_galois_extends h_fin hna,
end

/-- If `L/K` is finite and normal, and `f` is a power-multiplicative `K`-algebra norm on `L`
  extending the norm on `K`, then `f = spectral_norm K L`. -/
lemma spectral_norm_unique_of_fd_normal (h_alg : algebra.is_algebraic K L)
  (h_fin : finite_dimensional K L) (hn : normal K L) {f : algebra_norm K L} (hf_pm : is_pow_mul f)
  (hf_na : is_nonarchimedean f) (hf_ext : function_extends (λ x : K, ‖ x ‖₊) f)
  (hf_iso : ∀ (σ : L ≃ₐ[K] L) (x : L), f x = f (σ x)) (x : L) : f x = spectral_norm K L x :=
begin
  have h_sup : supr (λ (σ : L ≃ₐ[K] L), f (σ x)) = f x,
  { rw ← @csupr_const _ (L ≃ₐ[K] L) _ _ (f x),
    exact supr_congr (λ σ, by rw hf_iso σ x), },
  rw [spectral_norm_max_of_fd_normal h_alg h_fin hn hf_pm  hf_na hf_ext, h_sup]
end

end normal

end finite

-- Now we let L/K be any algebraic extension

/-- The spectral norm is a power-multiplicative K-algebra norm on L extending the norm on K. -/
lemma spectral_value.eq_normal' (h_alg_L : algebra.is_algebraic K L) 
  {E : intermediate_field K L} {x : L} (g : E) (h_map : algebra_map E L g = x) :
  spectral_norm K (normal_closure K E (algebraic_closure E))
    (algebra_map E (normal_closure K E (algebraic_closure E)) g) = spectral_norm K L x :=
begin
  rw ← h_map,
  exact spectral_value.eq_normal E h_alg_L g,
end

/-- The spectral norm is power-multiplicative. -/
lemma spectral_norm_is_pow_mul (h_alg : algebra.is_algebraic K L) 
  (hna : is_nonarchimedean (norm : K → ℝ)) : is_pow_mul (spectral_norm K L) :=
begin
  intros x n hn,
  set E := K⟮x⟯ with hE,
  haveI h_fd_E : finite_dimensional K E := 
  intermediate_field.adjoin.finite_dimensional (is_algebraic_iff_is_integral.mp (h_alg x)),
  have h_alg_E : algebra.is_algebraic K E := intermediate_field.is_algebraic h_alg E,
  set g := intermediate_field.adjoin_simple.gen K x with hg,
  have h_map : algebra_map E L g^n = x^n := rfl,
  haveI h_normal : normal K (algebraic_closure ↥K⟮x⟯) := 
  intermediate_field.adjoin_simple.alg_closure_normal h_alg x,
  rw [← spectral_value.eq_normal' h_alg  _ (intermediate_field.adjoin_simple.algebra_map_gen K x),
    ← spectral_value.eq_normal' h_alg (g^n) h_map, map_pow],
  exact spectral_norm_is_pow_mul_of_fd_normal (normal_closure.is_algebraic K E h_alg_E)
    (normal_closure.is_finite_dimensional K E _) (normal_closure.normal K E _) hna _ hn,
end

/-- The spectral norm is compatible with the action of `K`. -/
lemma spectral_norm_smul (h_alg : algebra.is_algebraic K L) (hna : is_nonarchimedean (norm : K → ℝ))
  (k : K) (y : L) : spectral_norm K L (k • y) = ‖ k ‖₊ * spectral_norm K L y :=
begin
  set E := K⟮y⟯ with hE,
  haveI : normal K (algebraic_closure ↥E) := 
  intermediate_field.adjoin_simple.alg_closure_normal h_alg y,
  haveI h_fd_E : finite_dimensional K E := 
  intermediate_field.adjoin.finite_dimensional (is_algebraic_iff_is_integral.mp (h_alg y)),
  have h_alg_E : algebra.is_algebraic K E := intermediate_field.is_algebraic h_alg E,
  set g := intermediate_field.adjoin_simple.gen K y with hg,
  have hgy : k • y = (algebra_map ↥K⟮y⟯ L) (k • g) := rfl,
  have h : algebra_map K⟮y⟯ (normal_closure K K⟮y⟯ (algebraic_closure K⟮y⟯)) (k • g) = 
    k • algebra_map K⟮y⟯ (normal_closure K K⟮y⟯ (algebraic_closure K⟮y⟯)) g,
  { rw [algebra.algebra_map_eq_smul_one, algebra.algebra_map_eq_smul_one, smul_assoc] },
    rw [← spectral_value.eq_normal' h_alg g (intermediate_field.adjoin_simple.algebra_map_gen K y),
      hgy, ← spectral_value.eq_normal' h_alg (k • g) rfl, h],
    have h_alg' := normal_closure.is_algebraic K E h_alg_E,
    rw ← spectral_alg_norm_of_fd_normal_def h_alg' 
      (normal_closure.is_finite_dimensional K E (algebraic_closure E)) 
      (normal_closure.normal K E _) hna,
    exact map_smul_eq_mul _ _ _,    
end

/-- The spectral norm is nonarchimedean. -/
lemma spectral_norm_is_nonarchimedean (h_alg : algebra.is_algebraic K L)
  (h : is_nonarchimedean (norm : K → ℝ)) : is_nonarchimedean (spectral_norm K L) :=
begin
  intros x y,
  set E := K⟮x, y⟯ with hE,
  haveI : normal K (algebraic_closure ↥E) := 
  intermediate_field.adjoin_double.alg_closure_normal h_alg x y,
  haveI h_fd_E : finite_dimensional K E :=
  intermediate_field.adjoin_adjoin.finite_dimensional (is_algebraic_iff_is_integral.mp (h_alg x))
    (is_algebraic_iff_is_integral.mp (h_alg y)),
  have h_alg_E : algebra.is_algebraic K E := intermediate_field.is_algebraic h_alg E,
  set gx := intermediate_field.adjoin_adjoin.gen_1 K x y with hgx,
  set gy := intermediate_field.adjoin_adjoin.gen_2 K x y with hgy,
  have hxy : x + y = (algebra_map K⟮x, y⟯ L) (gx + gy) := rfl,
  rw [hxy, ← spectral_value.eq_normal' h_alg (gx + gy) hxy,
    ← spectral_value.eq_normal' h_alg gx (intermediate_field.adjoin_adjoin.algebra_map_gen_1
    K x y), ← spectral_value.eq_normal' h_alg gy (intermediate_field.adjoin_adjoin.algebra_map_gen_2
    K x y), _root_.map_add],
  exact spectral_norm_is_nonarchimedean_of_fd_normal (normal_closure.is_algebraic K E h_alg_E)
    (normal_closure.is_finite_dimensional K E _)  (normal_closure.normal K E _) h _ _, 
end

/-- The spectral norm is submultiplicative. -/
lemma spectral_norm_mul (h_alg : algebra.is_algebraic K L) 
  (hna : is_nonarchimedean (norm : K → ℝ)) (x y : L)  :
  spectral_norm K L (x * y) ≤ spectral_norm K L x * spectral_norm K L y :=
begin
  set E := K⟮x, y⟯ with hE,
  haveI : normal K (algebraic_closure ↥E) := 
  intermediate_field.adjoin_double.alg_closure_normal h_alg x y,
  haveI h_fd_E : finite_dimensional K E :=
  intermediate_field.adjoin_adjoin.finite_dimensional (is_algebraic_iff_is_integral.mp (h_alg x))
    (is_algebraic_iff_is_integral.mp (h_alg y)),
  have h_alg_E : algebra.is_algebraic K E := intermediate_field.is_algebraic h_alg E,
  set gx := intermediate_field.adjoin_adjoin.gen_1 K x y with hgx,
  set gy := intermediate_field.adjoin_adjoin.gen_2 K x y with hgy,
  have hxy : x * y = (algebra_map K⟮x, y⟯ L) (gx * gy) := rfl,
  rw [hxy, ← spectral_value.eq_normal' h_alg (gx*gy) hxy,
    ← spectral_value.eq_normal' h_alg gx (intermediate_field.adjoin_adjoin.algebra_map_gen_1
    K x y), ← spectral_value.eq_normal' h_alg gy (intermediate_field.adjoin_adjoin.algebra_map_gen_2
    K x y), map_mul, ← spectral_alg_norm_of_fd_normal_def (normal_closure.is_algebraic K E h_alg_E)
    (normal_closure.is_finite_dimensional K E (algebraic_closure E)) 
    (normal_closure.normal K E _) hna],
  exact map_mul_le_mul _ _ _
end

/-- The spectral norm extends the norm on `K`. -/
lemma spectral_norm_extends (k : K) : spectral_norm K L (algebra_map K L k) = ‖ k ‖ :=
begin
  simp_rw [spectral_norm, minpoly.eq_X_sub_C_of_algebra_map_inj _ (algebra_map K L).injective],
  exact spectral_value_X_sub_C k,
end

/-- `spectral_norm K L (-y) = spectral_norm K L y` . -/
lemma spectral_norm_neg (h_alg : algebra.is_algebraic K L)
  (hna : is_nonarchimedean (norm : K → ℝ)) (y : L) :
  spectral_norm K L (-y) = spectral_norm K L y :=
begin
  set E := K⟮y⟯ with hE,
  haveI : normal K (algebraic_closure ↥E) := 
  intermediate_field.adjoin_simple.alg_closure_normal h_alg y,
  haveI h_fd_E : finite_dimensional K E := 
  intermediate_field.adjoin.finite_dimensional (is_algebraic_iff_is_integral.mp (h_alg y)),
  have h_alg_E : algebra.is_algebraic K E := intermediate_field.is_algebraic h_alg E,
  set g := intermediate_field.adjoin_simple.gen K y with hg,
  have hy : - y = (algebra_map K⟮y⟯ L) (- g) := rfl,
  rw [← spectral_value.eq_normal' h_alg g (intermediate_field.adjoin_simple.algebra_map_gen K y), 
    hy, ← spectral_value.eq_normal' h_alg (-g) hy, map_neg, ← spectral_alg_norm_of_fd_normal_def 
      (normal_closure.is_algebraic K E h_alg_E)(normal_closure.is_finite_dimensional K E 
      (algebraic_closure E)) (normal_closure.normal K E _) hna],
    exact map_neg_eq_map _ _
end

/-- The spectral norm is a `K`-algebra norm on `L`. -/
def spectral_alg_norm (h_alg : algebra.is_algebraic K L) (hna : is_nonarchimedean (norm : K → ℝ)) :
  algebra_norm K L:=
{ to_fun    := spectral_norm K L,
  map_zero' := spectral_norm_zero,
  add_le'   := add_le_of_is_nonarchimedean spectral_norm_nonneg
    (spectral_norm_is_nonarchimedean h_alg hna),
  mul_le'   := spectral_norm_mul h_alg hna,
  smul'     := spectral_norm_smul h_alg hna,
  neg'      := spectral_norm_neg h_alg hna,
  eq_zero_of_map_eq_zero' := λ x hx, eq_zero_of_map_spectral_norm_eq_zero h_alg hx }

lemma spectral_alg_norm_def (h_alg : algebra.is_algebraic K L)
  (hna : is_nonarchimedean (norm : K → ℝ)) (x : L) : 
  spectral_alg_norm h_alg hna x = spectral_norm K L x := 
rfl

lemma spectral_alg_norm_extends (h_alg : algebra.is_algebraic K L) (k : K)
  (hna : is_nonarchimedean (norm : K → ℝ)) :
  spectral_alg_norm h_alg hna (algebra_map K L k) = ‖ k ‖ :=
spectral_norm_extends k

lemma spectral_norm_is_norm_le_one_class : spectral_norm K L 1 ≤ 1 :=
begin
  have h1 : (1 : L) = (algebra_map K L 1) := by rw map_one,
  rw [h1, spectral_norm_extends, norm_one],
end

lemma spectral_alg_norm_is_norm_le_one_class (h_alg : algebra.is_algebraic K L)
  (hna : is_nonarchimedean (norm : K → ℝ)) : spectral_alg_norm h_alg hna 1 ≤ 1 :=
spectral_norm_is_norm_le_one_class

lemma spectral_norm_is_norm_one_class : spectral_norm K L 1 = 1 :=
begin
  have h1 : (1 : L) = (algebra_map K L 1) := by rw map_one,
  rw [h1, spectral_norm_extends, norm_one],
end

lemma spectral_alg_norm_is_norm_one_class (h_alg : algebra.is_algebraic K L)
  (hna : is_nonarchimedean (norm : K → ℝ)) : spectral_alg_norm h_alg hna 1 = 1 :=
spectral_norm_is_norm_one_class

lemma spectral_alg_norm_is_pow_mul (h_alg : algebra.is_algebraic K L)
  (hna : is_nonarchimedean (norm : K → ℝ)) : is_pow_mul (spectral_alg_norm h_alg hna) := 
spectral_norm_is_pow_mul h_alg hna

/-- The restriction of a `K`-algebra norm on `L` to an intermediate field `K⟮x⟯`. -/
def adjoin.algebra_norm (f : algebra_norm K L) (x : L) : 
  algebra_norm K K⟮x⟯ := 
{ to_fun    := (f ∘ (algebra_map ↥K⟮x⟯ L)),
  map_zero' := by simp only [function.comp_app, _root_.map_zero],
  add_le'   := λ a b, by { simp only [function.comp_app, _root_.map_add, map_add_le_add] },
  mul_le'   := λ a b, by { simp only [function.comp_app, map_mul, map_mul_le_mul] },
  smul'     := λ r a, 
  begin
    simp only [function.comp_app, algebra.smul_def],
    rw [map_mul, ← ring_hom.comp_apply, ← is_scalar_tower.algebra_map_eq, ← algebra.smul_def, 
      map_smul_eq_mul _ _],
  end,
  neg'      := λ a, by { simp only [function.comp_app, map_neg, map_neg_eq_map] },
  eq_zero_of_map_eq_zero' := λ a ha, 
  begin 
    simp only [function.comp_app, map_eq_zero_iff_eq_zero, _root_.map_eq_zero] at ha,
    exact ha,
  end  }

end spectral_norm

section spectral_valuation

variables {K : Type*} [normed_field K] [complete_space K] {L : Type*} [hL : field L] [algebra K L]
(h_alg : algebra.is_algebraic K L)

include hL

-- Theorem 3.2.4/2

section

omit hL

/-- The `normed_ring` stucture on a ring `A` determined by a `ring_norm`. -/
def norm_to_normed_ring {A : Type*} [ring A] (f : ring_norm A):
  normed_ring A := 
{ norm          := λ x, f x,
  dist          := λ x y, f (x - y),
  dist_self     := λ x, by simp only [sub_self, _root_.map_zero],
  dist_comm     := λ x y, by simp only [← neg_sub x y, map_neg_eq_map],
  dist_triangle := λ x y z, begin
    have hxyz : x - z = x - y + (y - z) := by abel,
    simp only [hxyz, map_add_le_add],
  end,
  eq_of_dist_eq_zero := λ x y hxy, eq_of_sub_eq_zero (ring_norm.eq_zero_of_map_eq_zero' _ _ hxy),
  dist_eq := λ x y, rfl,
  norm_mul := λ x y, by simp only [map_mul_le_mul], }
end

/-- The `normed_field` stucture on a field `L` determined by a `mul_ring_norm`. -/
def mul_norm_to_normed_field (f : mul_ring_norm L) :
  normed_field L := 
{ norm          := λ x, f x,
  dist          := λ x y, f (x - y),
  dist_self     := λ x, by simp only [sub_self, _root_.map_zero],
  dist_comm     := λ x y, by simp only [← neg_sub x y, map_neg_eq_map],
  dist_triangle := λ x y z, begin
    have hxyz : x - z = x - y + (y - z) := by ring, 
    simp only [hxyz, map_add_le_add],
  end,
  eq_of_dist_eq_zero :=
   λ x y hxy, eq_of_sub_eq_zero (mul_ring_norm.eq_zero_of_map_eq_zero' _ _ hxy),
  dist_eq := λ x y, rfl,
  norm_mul' := λ x y, by simp only [map_mul],} 

lemma mul_norm_to_normed_field.norm (f : mul_ring_norm L) :
  (mul_norm_to_normed_field f).norm = λ x, (f x : ℝ) := 
rfl

end spectral_valuation
