import { ref } from "vue";
import confettiAudio from "@/assets/audio/confetti.mp3";

const showConfetti = ref(false);
let confettiTimeout: ReturnType<typeof setTimeout> | null = null;

/**
 * Singleton confetti composable.
 *
 * No matter how many cards change status at once, only a single confetti
 * explosion + sound will play.  Subsequent calls while an explosion is
 * already active are silently ignored.
 */
export function useConfetti() {
  function trigger() {
    // Already showing – skip
    if (showConfetti.value) return;

    showConfetti.value = true;

    try {
      const audio = new Audio(confettiAudio);
      audio.volume = 0.5;
      audio.play().catch(console.error);
    } catch (error) {
      console.error("Error playing confetti sound:", error);
    }

    if (confettiTimeout) clearTimeout(confettiTimeout);
    confettiTimeout = setTimeout(() => {
      showConfetti.value = false;
      confettiTimeout = null;
    }, 3000);
  }

  return { showConfetti, trigger };
}
