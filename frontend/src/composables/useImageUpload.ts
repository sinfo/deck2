import { ref } from "vue";

const MAX_FILE_SIZE = 10 << 20; // 10MB

export function useImageUpload() {
  const imagePreview = ref<string>("");
  const selectedImageFile = ref<File | null>(null);
  const imageInputMode = ref<string>("file");
  const imageUrl = ref<string>("");
  const isLoadingImageUrl = ref<boolean>(false);
  const imageError = ref<string>("");

  const clearError = () => {
    imageError.value = "";
  };

  const setError = (message: string) => {
    imageError.value = message;
  };

  const handleFileChange = (event: Event) => {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (file) {
      // Check file size (10MB limit)
      if (file.size > MAX_FILE_SIZE) {
        setError("Image file size must be less than 10MB");
        return;
      }

      clearError();
      selectedImageFile.value = file;

      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        imagePreview.value = e.target?.result as string;
      };
      reader.readAsDataURL(file);
    }
  };

  const handleUrlChange = async () => {
    const url = imageUrl.value.trim();
    if (!url) {
      return;
    }

    // Validate URL format
    try {
      new URL(url);
    } catch {
      setError("Please enter a valid URL");
      return;
    }

    isLoadingImageUrl.value = true;
    clearError();

    try {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error("Failed to fetch image");
      }

      const contentType = response.headers.get("content-type");
      if (!contentType || !contentType.startsWith("image/")) {
        throw new Error("URL does not point to a valid image");
      }

      const blob = await response.blob();

      // Check file size (10MB limit)
      if (blob.size > MAX_FILE_SIZE) {
        setError("Image file size must be less than 10MB");
        isLoadingImageUrl.value = false;
        return;
      }

      // Extract filename from URL or use a default
      const urlPath = new URL(url).pathname;
      const filename = urlPath.split("/").pop() || "image";
      const extension = contentType.split("/")[1] || "png";
      const finalFilename = filename.includes(".")
        ? filename
        : `${filename}.${extension}`;

      // Create a File object from the blob
      const file = new File([blob], finalFilename, { type: contentType });
      selectedImageFile.value = file;

      // Create preview
      const reader = new FileReader();
      reader.onload = (e) => {
        imagePreview.value = e.target?.result as string;
      };
      reader.readAsDataURL(blob);
    } catch (error) {
      console.error("Error fetching image from URL:", error);
      setError(
        "Failed to load image from URL. Please check the URL and try again.",
      );
    } finally {
      isLoadingImageUrl.value = false;
    }
  };

  const reset = () => {
    imagePreview.value = "";
    selectedImageFile.value = null;
    imageInputMode.value = "file";
    imageUrl.value = "";
    isLoadingImageUrl.value = false;
    imageError.value = "";
  };

  return {
    imagePreview,
    selectedImageFile,
    imageInputMode,
    imageUrl,
    isLoadingImageUrl,
    imageError,
    handleFileChange,
    handleUrlChange,
    clearError,
    setError,
    reset,
  };
}
