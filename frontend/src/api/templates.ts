import { instance } from ".";

export const getTemplates = (params?: { event?: number; name?: string }) =>
  instance.get("/templates", { params });

export const uploadTemplate = (
  templateId: string,
  eventId: number,
  file: File,
) => {
  const fd = new FormData();
  fd.append("file", file);
  return instance.post(`/templates/${templateId}/upload`, fd, {
    params: { event: eventId },
    headers: { "Content-Type": "multipart/form-data" },
  });
};

export const downloadTemplate = (templateId: string) =>
  instance.get(`/templates/${templateId}/download`, { responseType: "blob" });

export const createDefaultTemplates = (eventId: number) =>
  instance.post(`/templates/create-defaults`, null, {
    params: { event: eventId },
  });
