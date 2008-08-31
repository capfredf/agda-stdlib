------------------------------------------------------------------------
-- A binary representation of natural numbers
------------------------------------------------------------------------

module Data.Bin where

import Data.Nat as Nat
open Nat using (ℕ; z≤n; s≤s)
open Nat.≤-Reasoning
import Data.Nat.Properties as NP
open import Data.Digit
import Data.Fin as Fin
open Fin using (Fin; zero) renaming (suc to 1+_)
import Data.Fin.Props as FP
open FP using (_+′_)
open import Data.List
open import Data.Function
open import Data.Product
open import Algebra
open import Relation.Binary
open import Relation.Binary.Consequences
open import Relation.Binary.PropositionalEquality
open import Relation.Nullary
private
  module BitOrd = StrictTotalOrder (FP.strictTotalOrder 2)

------------------------------------------------------------------------
-- The type

-- A representation of binary natural numbers in which there is
-- exactly one representative for every number.

-- The function toℕ below defines the meaning of Bin.

infix 8 _1#

-- bs stands for the binary number 1<reverse bs>, which is positive.

Bin⁺ : Set
Bin⁺ = List Bit

data Bin : Set where
  -- Zero.
  0#  : Bin
  -- bs 1# stands for the binary number 1<reverse bs>.
  _1# : (bs : Bin⁺) -> Bin

------------------------------------------------------------------------
-- Conversion functions

-- Converting to a list of bits starting with the _least_ significant
-- one.

toBits : Bin -> List Bit
toBits 0#      = [ 0b ]
toBits (bs 1#) = bs ++ [ 1b ]

-- Converting to a natural number.

toℕ : Bin -> ℕ
toℕ = fromDigits ∘ toBits

-- Converting from a list of bits, starting with the _most_
-- significant one.

fromBits' : List Bit -> Bin
fromBits' []              = 0#
fromBits' (zero     ∷ bs) = fromBits' bs
fromBits' (1+ zero  ∷ bs) = reverse bs 1#
fromBits' (1+ 1+ () ∷ _)

-- Converting from a list of bits, starting with the _least_
-- significant one.

fromBits : List Bit -> Bin
fromBits = fromBits' ∘ reverse

-- Converting from a natural number.

fromℕ : ℕ -> Bin
fromℕ n                with toDigits 2 n
fromℕ .(fromDigits bs) | digits bs = fromBits bs

------------------------------------------------------------------------
-- (Bin, _≡_, _<_) is a strict total order

infix 4 _<_

-- Order relation. Wrapped so that the parameters can be inferred.

data _<_ (b₁ b₂ : Bin) : Set where
  less : (lt : (Nat._<_ on₁ toℕ) b₁ b₂) -> b₁ < b₂

private
  <-trans : Transitive _<_
  <-trans (less lt₁) (less lt₂) = less (NP.<-trans lt₁ lt₂)

  asym : forall {b₁ b₂} -> b₁ < b₂ -> ¬ b₂ < b₁
  asym {b₁} {b₂} (less lt) (less gt) = tri⟶asym cmp lt gt
    where cmp = StrictTotalOrder.compare NP.strictTotalOrder

  irr : forall {b₁ b₂} -> b₁ < b₂ -> b₁ ≢ b₂
  irr lt eq = asym⟶irr (≡-resp _<_) ≡-sym asym eq lt

  irr′ : forall {b} -> ¬ b < b
  irr′ lt = irr lt ≡-refl

  ∷∙ : forall {b₁ b₂ bs₁ bs₂} ->
       bs₁ 1# < bs₂ 1# -> (b₁ ∷ bs₁) 1# < (b₂ ∷ bs₂) 1#
  ∷∙ {b₁} {b₂} {bs₁} {bs₂} (less lt) = less (begin
      1 + (m₁ + n₁ * 2)  ≤⟨ refl {x = 1} +-mono
                              (≤-pred (FP.bounded b₁) +-mono refl) ⟩
      1 + (1  + n₁ * 2)  ≡⟨ ≡-refl ⟩
            suc n₁ * 2   ≤⟨ lt *-mono refl ⟩
                n₂ * 2   ≤⟨ n≤m+n m₂ (n₂ * 2) ⟩
           m₂ + n₂ * 2   ∎
    )
    where
    open Nat; open NP; open Poset poset using (refl)
    m₁ = Fin.toℕ b₁;   m₂ = Fin.toℕ b₂
    n₁ = toℕ (bs₁ 1#); n₂ = toℕ (bs₂ 1#)

  ∙∷ : forall {b₁ b₂ bs} ->
       Fin._<_ b₁ b₂ -> (b₁ ∷ bs) 1# < (b₂ ∷ bs) 1#
  ∙∷ {b₁} {b₂} {bs} lt = less (begin
    1 + (m₁  + n * 2)  ≡⟨ ≡-sym (+-assoc 1 m₁ (n * 2)) ⟩
    (1 + m₁) + n * 2   ≤⟨ lt +-mono refl ⟩
         m₂  + n * 2   ∎)
    where
    open Nat; open NP
    open Poset poset using (refl)
    open CommutativeSemiring commutativeSemiring using (+-assoc)
    m₁ = Fin.toℕ b₁; m₂ = Fin.toℕ b₂; n = toℕ (bs 1#)

  1<[23] : forall {b} -> [] 1# < (b ∷ []) 1#
  1<[23] {b} = less (NP.n≤m+n (Fin.toℕ b) 2)

  1<2+ : forall {bs b} -> [] 1# < (b ∷ bs) 1#
  1<2+ {[]}     = 1<[23]
  1<2+ {b ∷ bs} = <-trans 1<[23] (∷∙ {b₁ = b} (1<2+ {bs}))

  0<1 : 0# < [] 1#
  0<1 = less (s≤s z≤n)

  0<+ : forall {bs} -> 0# < bs 1#
  0<+ {[]}     = 0<1
  0<+ {b ∷ bs} = <-trans 0<1 1<2+

  compare⁺ : Trichotomous (_≡_ on₁ _1#) (_<_ on₁ _1#)
  compare⁺ []         []         = tri≈ irr′ ≡-refl irr′
  compare⁺ []         (b ∷ bs)   = tri<       1<2+  (irr 1<2+)   (asym 1<2+)
  compare⁺ (b ∷ bs)   []         = tri> (asym 1<2+) (irr 1<2+ ∘ ≡-sym) 1<2+
  compare⁺ (b₁ ∷ bs₁) (b₂ ∷ bs₂) with compare⁺ bs₁ bs₂
  ... | tri<  lt ¬eq ¬gt = tri<       (∷∙ lt)  (irr (∷∙ lt))   (asym (∷∙ lt))
  ... | tri> ¬lt ¬eq  gt = tri> (asym (∷∙ gt)) (irr (∷∙ gt) ∘ ≡-sym) (∷∙ gt)
  compare⁺ (b₁ ∷ bs) (b₂ ∷ .bs) | tri≈ ¬lt ≡-refl ¬gt with BitOrd.compare b₁ b₂
  compare⁺ (b  ∷ bs) (.b ∷ .bs) | tri≈ ¬lt ≡-refl ¬gt | tri≈ ¬lt′ ≡-refl ¬gt′ =
    tri≈ irr′ ≡-refl irr′
  ... | tri<  lt′ ¬eq ¬gt′ = tri<       (∙∷ lt′)  (irr (∙∷ lt′))   (asym (∙∷ lt′))
  ... | tri> ¬lt′ ¬eq  gt′ = tri> (asym (∙∷ gt′)) (irr (∙∷ gt′) ∘ ≡-sym) (∙∷ gt′)

  compare : Trichotomous _≡_ _<_
  compare 0#       0#       = tri≈ irr′ ≡-refl irr′
  compare 0#       (bs₂ 1#) = tri<       0<+  (irr 0<+)   (asym 0<+)
  compare (bs₁ 1#) 0#       = tri> (asym 0<+) (irr 0<+ ∘ ≡-sym) 0<+
  compare (bs₁ 1#) (bs₂ 1#) = compare⁺ bs₁ bs₂

strictTotalOrder : StrictTotalOrder
strictTotalOrder = record
  { carrier            = Bin
  ; _≈_                = _≡_
  ; _<_                = _<_
  ; isStrictTotalOrder = record
    { isEquivalence = ≡-isEquivalence
    ; trans         = <-trans
    ; compare       = compare
    ; ≈-resp-<      = ≡-resp _<_
    }
  }

------------------------------------------------------------------------
-- (Bin, _≡_) is a decidable setoid

decSetoid : DecSetoid
decSetoid = StrictTotalOrder.decSetoid strictTotalOrder

infix 4 _≟_

_≟_ : Decidable {Bin} _≡_
_≟_ = DecSetoid._≟_ decSetoid

------------------------------------------------------------------------
-- Arithmetic

-- Multiplication by 2.

infix 7 _*2 _*2+1

_*2 : Bin -> Bin
0#      *2 = 0#
(bs 1#) *2 = (0b ∷ bs) 1#

_*2+1 : Bin -> Bin
0#      *2+1 = [] 1#
(bs 1#) *2+1 = (1b ∷ bs) 1#

-- Division by 2, rounded downwards.

⌊_/2⌋ : Bin -> Bin
⌊ 0#          /2⌋ = 0#
⌊ [] 1#       /2⌋ = 0#
⌊ (b ∷ bs) 1# /2⌋ = bs 1#

-- Addition.

Carry : Set
Carry = Bit

addBits : Carry -> Bit -> Bit -> Carry × Bit
addBits c b₁ b₂ with c +′ (b₁ +′ b₂)
... | zero          = (0b , 0b)
... | 1+ zero       = (0b , 1b)
... | 1+ 1+ zero    = (1b , 0b)
... | 1+ 1+ 1+ zero = (1b , 1b)
... | 1+ 1+ 1+ 1+ ()

addCarryToBitList : Carry -> List Bit -> List Bit
addCarryToBitList zero      bs             = bs
addCarryToBitList (1+ zero) []             = 1b ∷ []
addCarryToBitList (1+ zero) (zero    ∷ bs) = 1b ∷ bs
addCarryToBitList (1+ zero) (1+ zero ∷ bs) = 0b ∷ addCarryToBitList 1b bs
addCarryToBitList (1+ 1+ ()) _
addCarryToBitList _ ((1+ 1+ ()) ∷ _)

addBitLists : Carry -> List Bit -> List Bit -> List Bit
addBitLists c []         bs₂        = addCarryToBitList c bs₂
addBitLists c bs₁        []         = addCarryToBitList c bs₁
addBitLists c (b₁ ∷ bs₁) (b₂ ∷ bs₂) with addBits c b₁ b₂
... | (c' , b') = b' ∷ addBitLists c' bs₁ bs₂

infixl 6 _+_

_+_ : Bin -> Bin -> Bin
m + n = fromBits (addBitLists 0b (toBits m) (toBits n))

-- Multiplication.

infixl 7 _*_

_*_ : Bin -> Bin -> Bin
0#                 * n = 0#
[]              1# * n = n
-- (b + 2 * bs 1#) * n = b * n + 2 * (bs 1# * n)
(b        ∷ bs) 1# * n with bs 1# * n
(b        ∷ bs) 1# * n | 0#     = 0#
(zero     ∷ bs) 1# * n | bs' 1# = (0b ∷ bs') 1#
(1+ zero  ∷ bs) 1# * n | bs' 1# = n + (0b ∷ bs') 1#
((1+ 1+ ()) ∷ _) 1# * _ | _

-- Successor.

suc : Bin -> Bin
suc n = [] 1# + n

-- Division by 2, rounded upwards.

⌈_/2⌉ : Bin -> Bin
⌈ n /2⌉ = ⌊ suc n /2⌋
