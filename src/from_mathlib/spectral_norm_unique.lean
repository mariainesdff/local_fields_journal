/-
Copyright (c) 2023 María Inés de Frutos-Fernández. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: María Inés de Frutos-Fernández
-/
import from_mathlib.pow_mult_faithful
import from_mathlib.seminorm_from_const
import from_mathlib.spectral_norm
import analysis.normed_space.finite_dimension
import topology.algebra.module.finite_dimension

/-!
# Unique norm extension theorem

Let `K` be a field complete with respect to a nontrivial nonarchimedean multiplicative norm and 
`L/K` be an algebraic extension. We show that the spectral norm on `L` is a nonarchimedean 
multiplicative norm, and any power-multiplicative `K`-algebra norm on `L` coincides with the 
spectral norm. More over, if `L/K` is finite, then `L` is a complete space.
This result is [BGR, Theorem 3.2.4/2].

## Main Definitions

* `spectral_mul_alg_norm` : the spectral norm is a multiplicative `K`-algebra norm on `L`.

## Main Results
* `spectral_norm_unique'` : any power-multiplicative `K`-algebra norm on `L` coincides with the 
  spectral norm. 
* `spectral_norm_is_mul` : the spectral norm on `L` is multiplicative.
* `spectral_norm_complete_space` : if `L/K` is finite dimensional, then `L` is a complete space 
  with respect to topology induced by the spectral norm.

## References
* [S. Bosch, U. Güntzer, R. Remmert, *Non-Archimedean Analysis*][bosch-guntzer-remmert]

## Tags

spectral, spectral norm, unique, seminorm, norm, nonarchimedean
-/

noncomputable theory

open_locale nnreal

variables {K : Type*} [nontrivially_normed_field K] {L : Type*} [field L] [algebra K L]
  (h_alg : algebra.is_algebraic K L)

/--If `K` is a field complete with respect to a nontrivial nonarchimedean multiplicative norm and 
  `L/K` is an algebraic extension, then any power-multiplicative `K`-algebra norm on `L` coincides
  with the spectral norm. -/
lemma spectral_norm_unique' [complete_space K] {f : algebra_norm K L} (hf_pm : is_pow_mul f)
  (hna : is_nonarchimedean (norm : K → ℝ)) : f = spectral_alg_norm h_alg hna := 
begin
  apply eq_of_pow_mult_faithful f hf_pm _
    (spectral_alg_norm_is_pow_mul h_alg hna),
  intro x,
  set E : Type* := id K⟮x⟯ with hEdef,
  letI hE : field E := (by rw [hEdef, id.def] ; apply_instance),
  letI : algebra K E := K⟮x⟯.algebra,
  set id1 : K⟮x⟯ →ₗ[K] E := 
  { to_fun := id,
    map_add' := λ x y, rfl,
    map_smul' := λ r x, rfl, },
  set id2 : E →ₗ[K] K⟮x⟯ := 
  { to_fun := id,
    map_add' := λ x y, rfl,
    map_smul' := λ r x, rfl },
  set hs_norm : ring_norm E :=
  { to_fun    := (λ y : E, spectral_norm K L (id2 y : L)),
    map_zero' := by rw [map_zero, subfield.coe_zero, spectral_norm_zero],
    add_le'   := λ a b, 
    by simp only [← spectral_alg_norm_def h_alg hna, subfield.coe_add]; exact map_add_le_add _ _ _,
    neg'      := λ a, 
    by simp only [← spectral_alg_norm_def h_alg hna, subfield.coe_neg, map_neg, map_neg_eq_map],
    mul_le'  := λ a b,
    by simp only [← spectral_alg_norm_def h_alg hna, subfield.coe_mul]; exact map_mul_le_mul _ _ _,
    eq_zero_of_map_eq_zero' := λ a ha,
    begin
      simp only [←spectral_alg_norm_def h_alg hna, linear_map.coe_mk, id.def,
        map_eq_zero_iff_eq_zero, algebra_map.lift_map_eq_zero_iff] at ha,
      exact ha
    end },
  letI n1 : normed_ring E := norm_to_normed_ring hs_norm,
  letI N1 : normed_space K E := 
  { norm_smul_le := λ k y,
    begin
      change (spectral_alg_norm h_alg hna (id2 (k • y) : L) : ℝ) ≤ 
        ‖ k ‖ * spectral_alg_norm h_alg hna (id2 y : L),
      simp only [linear_map.coe_mk, id.def, intermediate_field.coe_smul, map_smul_eq_mul],
    end,
    ..K⟮x⟯.algebra },
  set hf_norm : ring_norm K⟮x⟯ := 
  { to_fun := λ y, f((algebra_map K⟮x⟯ L) y),
    map_zero' := map_zero _,
    add_le'  := λ a b, map_add_le_add _ _ _,
    neg' := λ y, by { simp only [map_neg, map_neg_eq_map] },
    mul_le'  := λ a b, map_mul_le_mul _ _ _,
    eq_zero_of_map_eq_zero' := λ a ha,
    begin
      simp only [map_eq_zero_iff_eq_zero, map_eq_zero] at ha,
      exact ha
    end },
  letI n2 : normed_ring K⟮x⟯ := norm_to_normed_ring hf_norm,
  letI N2 : normed_space K K⟮x⟯ :=
  { norm_smul_le :=  λ k y,
    begin
      change (f ((algebra_map K⟮x⟯ L) (k • y)) : ℝ) ≤ ‖ k ‖ * f (algebra_map K⟮x⟯ L y),
      have : (algebra_map ↥K⟮x⟯ L) (k • y) = k • (algebra_map ↥K⟮x⟯ L y),
      { rw [← is_scalar_tower.algebra_map_smul K⟮x⟯ k y, smul_eq_mul, map_mul, 
          ← is_scalar_tower.algebra_map_apply K ↥K⟮x⟯ L, algebra.smul_def] }, 
      rw [ this, map_smul_eq_mul],
    end,
    ..K⟮x⟯.algebra },
  haveI hKx_fin : finite_dimensional K ↥K⟮x⟯ := intermediate_field.adjoin.finite_dimensional 
    (is_algebraic_iff_is_integral.mp (h_alg x)),
  haveI : finite_dimensional K E := hKx_fin,
  set Id1 : K⟮x⟯ →L[K] E := ⟨id1, id1.continuous_of_finite_dimensional⟩ with hId1,
  set Id2 : E →L[K] K⟮x⟯ := ⟨id2, id2.continuous_of_finite_dimensional⟩ with hId2,
  have hC1 : ∃ (C1 : ℝ), 0 < C1 ∧ ∀ (y : K⟮x⟯), ‖ id1 y ‖ ≤ C1 * ‖ y ‖ := 
  Id1.is_bounded_linear_map.bound,
  have hC2 : ∃ (C2 : ℝ), 0 < C2 ∧ ∀ (y : E), ‖ id2 y ‖ ≤ C2 * ‖ y ‖ := 
  Id2.is_bounded_linear_map.bound,
  obtain ⟨C1, hC1_pos, hC1⟩ := hC1,
  obtain ⟨C2, hC2_pos, hC2⟩ := hC2,
  use [C2, C1, hC2_pos, hC1_pos],
  rw forall_and_distrib,
  split,
  { intro y, exact hC2 ⟨y, (intermediate_field.algebra_adjoin_le_adjoin K _) y.2⟩ },
  { intro y, exact hC1 ⟨y, (intermediate_field.algebra_adjoin_le_adjoin K _) y.2⟩ },
end

/-- If `K` is a field complete with respect to a nontrivial nonarchimedean multiplicative norm and 
  `L/K` is an algebraic extension, then any multiplicative ring norm on `L` extending the norm on
  `K` coincides with the spectral norm. -/
lemma spectral_norm_unique_field_norm_ext [complete_space K] (h_alg : algebra.is_algebraic K L)
  {f : mul_ring_norm L} (hf_ext : function_extends (norm : K → ℝ) f)
  (hna : is_nonarchimedean (norm : K → ℝ)) (x : L) :
  f x = spectral_norm K L x := 
begin
  set g : algebra_norm K L := 
  { smul' := λ k x, by simp only [mul_ring_norm.to_fun_eq_coe, algebra.smul_def, map_mul, hf_ext k],
    mul_le' := λ x y, by simp only [mul_ring_norm.to_fun_eq_coe, map_mul_le_mul], 
    ..f },
  have hg_pow : is_pow_mul g := mul_ring_norm.is_pow_mul _,
  have hgx : f x = g x := rfl,
  rw [hgx, spectral_norm_unique' h_alg hg_pow hna], refl,
end

/-- `seminorm_from_const` can be regarded as an algebra norm, when one assumes that
`(spectral_alg_norm h_alg hna).to_ring_seminorm 1 ≤ 1` and `0 ≠ spectral_alg_norm h_alg hna x`
for some `x : L` -/
def alg_norm_from_const (hna : is_nonarchimedean (norm : K → ℝ)) 
  (h1 : (spectral_alg_norm h_alg hna).to_ring_seminorm 1 ≤ 1) {x : L}
  (hx : 0 ≠ spectral_alg_norm h_alg hna x) : 
  algebra_norm K L  :=
{ smul' := λ k y,
  begin
    have h_mul : ∀ (y : L), spectral_norm K L ((algebra_map K L k) * y) = 
      spectral_norm K L (algebra_map K L k) * spectral_norm K L y,
    { intro y, 
      rw [spectral_norm_extends, ← algebra.smul_def,
        ← spectral_alg_norm_def h_alg hna, map_smul_eq_mul _ _ _],
      refl, },
    have h : spectral_norm K L (algebra_map K L k) = 
      seminorm_from_const' h1 hx (spectral_norm_is_pow_mul h_alg hna) (algebra_map K L k),
    {  rw seminorm_from_const_apply_of_is_mul h1 hx _ h_mul, refl, }, 
    simp only [ring_norm.to_fun_eq_coe, seminorm_from_const_ring_norm_of_field_def],
    rw [← spectral_norm_extends k, algebra.smul_def, h],
    exact seminorm_from_const_is_mul_of_is_mul _ _ _ h_mul _,
  end,
  ..(seminorm_from_const_ring_norm_of_field h1 hx.symm (spectral_alg_norm_is_pow_mul h_alg hna)) }

lemma alg_norm_from_const_def (hna : is_nonarchimedean (norm : K → ℝ)) 
  (h1 : (spectral_alg_norm h_alg hna).to_ring_seminorm 1 ≤ 1) {x y : L}
  (hx : 0 ≠ spectral_alg_norm h_alg hna x) : 
  alg_norm_from_const h_alg hna h1 hx y = 
    seminorm_from_const h1 hx (spectral_norm_is_pow_mul h_alg hna) y := 
rfl

/--If `K` is a field complete with respect to a nontrivial nonarchimedean multiplicative norm and 
  `L/K` is an algebraic extension, then the spectral norm on `L` is multiplicative. -/
lemma spectral_norm_is_mul [complete_space K] (hna : is_nonarchimedean (norm : K → ℝ))
  (x y : L) : spectral_alg_norm h_alg hna (x * y) = 
    spectral_alg_norm h_alg hna x * spectral_alg_norm h_alg hna y := 
begin
  by_cases hx : spectral_alg_norm h_alg hna x = 0,
  { rw [hx, zero_mul],
    rw [map_eq_zero_iff_eq_zero] at hx ⊢,
    rw [hx, zero_mul],  },
  { have hf1 : (spectral_alg_norm h_alg hna).to_ring_seminorm 1 ≤ 1 := 
    spectral_alg_norm_is_norm_le_one_class h_alg hna,
    set f : algebra_norm K L := alg_norm_from_const h_alg hna hf1 (ne.symm hx) with hf,
    have hf_pow : is_pow_mul f := seminorm_from_const_is_pow_mul hf1 (ne.symm hx)
      (spectral_norm_is_pow_mul h_alg hna),
    have hf_na : is_nonarchimedean f := 
    seminorm_from_const_is_nonarchimedean _ _ _ (spectral_norm_is_nonarchimedean h_alg hna),
    rw [← spectral_norm_unique' h_alg hf_pow, hf],
    simp only [alg_norm_from_const_def],
    exact seminorm_from_const_c_is_mul _ _ _ _, }
  end

/-- The spectral norm is a multiplicative `K`-algebra norm on `L`.-/
def spectral_mul_alg_norm [complete_space K] (hna : is_nonarchimedean (norm : K → ℝ)) : 
  mul_algebra_norm K L  :=
{ map_one' := spectral_alg_norm_is_norm_one_class h_alg hna,
  map_mul' := spectral_norm_is_mul h_alg hna,
  ..spectral_alg_norm h_alg hna }

lemma spectral_mul_ring_norm_def [complete_space K] (hna : is_nonarchimedean (norm : K → ℝ))
  (x : L) : spectral_mul_alg_norm h_alg hna x = spectral_norm K L x := 
rfl

/-- `L` with the spectral norm is a `normed_field`. -/
def spectral_norm_to_normed_field [complete_space K] (h_alg : algebra.is_algebraic K L) 
  (h : is_nonarchimedean (norm : K → ℝ)) : normed_field L := 
{ norm      := λ (x : L), (spectral_norm K L x : ℝ),
  dist      := λ (x y : L), (spectral_norm K L (x - y) : ℝ),
  dist_self := λ x, by { simp only [sub_self, spectral_norm_zero] },
  dist_comm := λ x y, by { simp only [dist], rw [← neg_sub, spectral_norm_neg h_alg h] },
  dist_triangle := λ x y z, begin
    simp only [dist_eq_norm],
    rw ← sub_add_sub_cancel x y z,
    exact add_le_of_is_nonarchimedean spectral_norm_nonneg 
      (spectral_norm_is_nonarchimedean h_alg h) _ _, 
  end,
  eq_of_dist_eq_zero := λ x y hxy,
  begin
    simp only [← spectral_mul_ring_norm_def h_alg h] at hxy,
    rw ← sub_eq_zero,
    exact mul_algebra_norm.eq_zero_of_map_eq_zero' _ _ hxy,
  end,
  dist_eq := λ x y, by refl,
  norm_mul' := λ x y, 
  by simp only [← spectral_mul_ring_norm_def h_alg h]; exact map_mul _ _ _,
  ..(infer_instance : field L) }

/-- `L` with the spectral norm is a `normed_add_comm_group`. -/
def spectral_norm_to_normed_add_comm_group [complete_space K] (h_alg : algebra.is_algebraic K L)
  (h : is_nonarchimedean (norm : K → ℝ)) : normed_add_comm_group L := 
begin
  haveI : normed_field L := spectral_norm_to_normed_field h_alg h,
  apply_instance,
end

/-- `L` with the spectral norm is a `seminormed_add_comm_group`. -/
def spectral_norm_to_seminormed_add_comm_group [complete_space K] (h_alg : algebra.is_algebraic K L)
  (h : is_nonarchimedean (norm : K → ℝ)) : seminormed_add_comm_group L := 
begin
  haveI : normed_field L := spectral_norm_to_normed_field h_alg h,
  apply_instance,
end

/-- `L` with the spectral norm is a `normed_space` over `K`. -/
def spectral_norm_to_normed_space [complete_space K] (h_alg : algebra.is_algebraic K L)
  (h : is_nonarchimedean (norm : K → ℝ)) : 
  @normed_space K L _ (spectral_norm_to_seminormed_add_comm_group h_alg h) := 
{ norm_smul_le := λ r x,
  begin
    change spectral_alg_norm h_alg h (r • x) ≤ ‖ r ‖*(spectral_alg_norm h_alg h x),
    exact le_of_eq (map_smul_eq_mul _ _ _),
  end,
  ..(infer_instance : module K L) }

/-- The metric space structure on `L` induced by the spectral norm. -/
def ms [complete_space K] (h : is_nonarchimedean (norm : K → ℝ)) : metric_space L := 
(spectral_norm_to_normed_field h_alg h).to_metric_space

/-- The uniform space structure on `L` induced by the spectral norm. -/
def us [complete_space K] (h : is_nonarchimedean (norm : K → ℝ)) : 
  uniform_space L := (ms h_alg h).to_uniform_space -- normed_field.to_uniform_space

/-- If `L/K` is finite dimensional, then `L` is a complete space with respect to topology induced
  by the spectral norm. -/
@[priority 100] instance spectral_norm_complete_space [complete_space K]
  (h : is_nonarchimedean (norm : K → ℝ)) [h_fin : finite_dimensional K L] :
  @complete_space L (us h_alg h) := 
@finite_dimensional.complete K _ L (spectral_norm_to_normed_add_comm_group h_alg h) 
  (spectral_norm_to_normed_space h_alg h) _ h_fin 