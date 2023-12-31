/-
Copyright (c) 2023 María Inés de Frutos-Fernández. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: María Inés de Frutos-Fernández
-/
import from_mathlib.rank_one_valuation
import from_mathlib.ring_seminorm
import topology.algebra.valuation

/-!
# Correspondence between nontrivial nonarchimedean norms and rank one valuations

Nontrivial nonarchimedean norms correspond to rank one valuations.

## Main Definitions
* `normed_field.to_valued` : the valued field structure on a nonarchimedean normed field `K`,
  determined by the norm.
* `valued_field.to_normed_field` : the normed field structure determined by a rank one valuation.

## Main Results
* `real.exists_strict_mono_lt` : if `Γ₀ˣ` is nontrivial and `f : Γ₀ →*₀ ℝ≥0` is a strict 
  monomorphism, then for any positive real `r`, there exists `d : Γ₀ˣ` with `f d < r`. 

## Tags

norm, nonarchimedean, nontrivial, valuation, rank one
-/

noncomputable theory

open_locale nnreal

variables {K : Type*} [hK : normed_field K]
include hK

/-- The valuation on a nonarchimedean normed field `K` defined as `nnnorm`. -/
def valuation_from_norm (h : is_nonarchimedean (norm : K → ℝ)) : valuation K ℝ≥0 := 
{ to_fun    := nnnorm,
  map_zero' := nnnorm_zero,
  map_one'  := nnnorm_one,
  map_mul'  := nnnorm_mul,
  map_add_le_max' := h }

lemma valuation_from_norm_apply (h : is_nonarchimedean (norm : K → ℝ)) (x : K):
  valuation_from_norm h x = ‖ x ‖₊ := rfl

/-- The valued field structure on a nonarchimedean normed field `K`, determined by the norm. -/
def normed_field.to_valued (h : is_nonarchimedean (norm : K → ℝ)) : valued K ℝ≥0 :=
{ v := valuation_from_norm h,
  is_topological_valuation := λ U,
  begin
    rw metric.mem_nhds_iff,
    refine ⟨λ h, _, λ h, _⟩, 
    { obtain ⟨ε, hε, h⟩ := h,
      use units.mk0 ⟨ε, le_of_lt hε⟩ (ne_of_gt hε),
      intros x hx,
      exact h (mem_ball_zero_iff.mpr hx) },
    { obtain ⟨ε, hε⟩ := h,
      use [(ε : ℝ), nnreal.coe_pos.mpr (units.zero_lt _)],
      intros x hx,
      exact hε  (mem_ball_zero_iff.mp hx) },
  end,
  ..hK.to_uniform_space,
  ..non_unital_normed_ring.to_normed_add_comm_group }

omit hK

variables {L : Type*} [hL : field L] {Γ₀ : Type*} [linear_ordered_comm_group_with_zero Γ₀]
  [val : valued L Γ₀] [hv : is_rank_one val.v]

/-- If `Γ₀ˣ` is nontrivial and `f : Γ₀ →*₀ ℝ≥0` is a strict monomorphism, then for any positive
  `r : ℝ≥0`, there exists `d : Γ₀ˣ` with `f d < r`. -/
lemma nnreal.exists_strict_mono_lt [h : nontrivial Γ₀ˣ] {f : Γ₀ →*₀ ℝ≥0} 
  (hf : strict_mono f) {r : ℝ≥0} (hr : 0 < r) :  ∃ d : Γ₀ˣ, f d < r :=
begin
  obtain ⟨g, hg1⟩ := (nontrivial_iff_exists_ne (1 : Γ₀ˣ)).mp h,
  set u : Γ₀ˣ := if g < 1 then g else g⁻¹ with hu,
  have hfu : f u < 1, 
  { rw hu,
    split_ifs with hu1,
    { rw ← map_one f, exact hf hu1, },
    { have hfg0 : f g ≠ 0,
      { intro h0,
        exact (units.ne_zero g)  ((map_eq_zero f).mp h0), },
      have hg1' : 1 < g,
      { exact lt_of_le_of_ne (not_lt.mp hu1) hg1.symm },
      simp only [units.coe_inv, map_inv₀],
      rw [nnreal.inv_lt_one_iff hfg0, ← map_one f],
      exact hf hg1', }},
  obtain ⟨n, hn⟩ := nnreal.exists_pow_lt_of_lt_one hr hfu,
  use u^n, 
  rw [units.coe_pow, map_pow],
  exact hn,
end

/-- If `Γ₀ˣ` is nontrivial and `f : Γ₀ →*₀ ℝ≥0` is a strict monomorphism, then for any positive
  real `r`, there exists `d : Γ₀ˣ` with `f d < r`. -/
lemma real.exists_strict_mono_lt [h : nontrivial Γ₀ˣ] {f : Γ₀ →*₀ ℝ≥0} (hf : strict_mono f) 
  {r : ℝ} (hr : 0 < r) :  ∃ d : Γ₀ˣ, (f d : ℝ) < r :=
begin
  set s : nnreal := ⟨r, le_of_lt hr⟩,
  have hs : 0 < s := hr,
  exact nnreal.exists_strict_mono_lt hf hs,
end

include hL val hv

namespace rank_one_valuation

/-- The norm function determined by a rank one valuation on a field `L`. -/
def norm_def : L → ℝ := λ x : L, hv.hom (valued.v x)

lemma norm_def_nonneg (x : L) : 0 ≤ norm_def x := by simp only [norm_def, nnreal.zero_le_coe]

lemma norm_def_add_le (x y : L) : 
  norm_def (x + y) ≤ max (norm_def x) (norm_def y) := 
begin
  simp only [norm_def, nnreal.coe_le_coe, le_max_iff, strict_mono.le_iff_le hv.strict_mono],
  exact le_max_iff.mp (valuation.map_add_le_max' val.v _ _),
end

lemma norm_def_eq_zero {x : L} (hx : norm_def x = 0) : x = 0 :=
by simpa [norm_def, nnreal.coe_eq_zero, is_rank_one_hom_eq_zero_iff, valuation.zero_iff] using hx


variables (L) (Γ₀)

/-- The normed field structure determined by a rank one valuation. -/
def valued_field.to_normed_field : normed_field L := 
{ norm               := norm_def,
  dist               := λ x y, norm_def (x - y),
  dist_self          := λ x, by simp only [sub_self, norm_def, valuation.map_zero, 
    (hv.hom).map_zero, nnreal.coe_zero],
  dist_comm          := λ x y, by { simp only [norm_def], rw [← neg_sub, valuation.map_neg] },
  dist_triangle      := λ x y z, 
  begin
    simp only [← sub_add_sub_cancel x y z], 
    exact le_trans (norm_def_add_le _ _)
      (max_le_add_of_nonneg (norm_def_nonneg _) (norm_def_nonneg _)), 
  end,
  eq_of_dist_eq_zero := λ x y hxy, eq_of_sub_eq_zero (norm_def_eq_zero hxy),
  dist_eq            := λ x y, rfl,
  norm_mul'          := λ x y, by { simp only [norm_def, ← nnreal.coe_mul, map_mul], },
  to_uniform_space   := valued.to_uniform_space,
  uniformity_dist    := 
  begin
    ext U,
    rw [filter.has_basis_iff.mp (valued.has_basis_uniformity L Γ₀), infi_subtype',
      filter.mem_infi_of_directed],
    { simp only [exists_true_left, filter.mem_principal, subtype.exists, gt_iff_lt, subtype.coe_mk, 
        exists_prop, true_and],
      refine ⟨λ h, _, λ h, _⟩,
      { obtain ⟨ε,  hε⟩ := h,
        set δ : ℝ≥0 := hv.hom ε with hδ,
        have hδ_pos : 0 < δ,
        { rw [hδ, ← map_zero hv.hom],
        exact hv.strict_mono (units.zero_lt ε), },
        use [δ, hδ_pos],
        apply subset_trans _ hε,
        intros x hx,
        simp only [set.mem_set_of_eq, norm_def, hδ, nnreal.val_eq_coe, nnreal.coe_lt_coe] at hx,
        rw [set.mem_set_of, ← neg_sub, valuation.map_neg],
        exact hv.strict_mono.lt_iff_lt.mp hx },
      { letI : nontrivial Γ₀ˣ := (nontrivial_iff_exists_ne (1 : Γ₀ˣ)).mpr 
          ⟨is_rank_one_unit val.v, is_rank_one_unit_ne_one val.v⟩,
        obtain ⟨r, hr_pos, hr⟩ := h,
        obtain ⟨u, hu⟩ := real.exists_strict_mono_lt hv.strict_mono hr_pos,
        use u,
        apply subset_trans _ hr,
        intros x hx,
        simp only [norm_def, set.mem_set_of_eq],
        apply lt_trans _ hu,
        rw [nnreal.coe_lt_coe, ← neg_sub, valuation.map_neg],
        exact hv.strict_mono.lt_iff_lt.mpr hx, }},
    { simp only [gt_iff_lt, ge_iff_le, directed],
      intros x y,
      use min x y,
      simp only [filter.le_principal_iff, filter.mem_principal, set.set_of_subset_set_of,
          prod.forall],
      exact ⟨λ a b hab, lt_of_lt_of_le hab (min_le_left _ _), 
        λ a b hab, lt_of_lt_of_le hab (min_le_right _ _)⟩ }
  end,
  ..hL, }

  end rank_one_valuation