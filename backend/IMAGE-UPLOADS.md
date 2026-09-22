# Product image uploads

In the web admin product editor, choose a JPEG or PNG under **Upload product image**, then select **Save Item**. A selected file takes precedence over the Image URL field. Limits: 5 MB and 16 megapixels.

`POST /api/images` accepts multipart field `file` and requires an ADMIN bearer token. It returns `{ "imageUrl": "http://host:port/api/images/<id>.png" }`. Images are decoded and saved as PNG with generated filenames. `GET /api/images/<id>.png` is public.

Docker stores images in the `caffora-images` named volume, preserved across container rebuilds. Local Java runs use `./uploads`, configurable with `caffora.upload-directory`. Back up the image volume together with MySQL; removing Docker volumes deletes stored files.

Use a backend hostname reachable by all clients when uploading images. A localhost URL works on the development computer but not a physical phone. Existing Image URL entries remain supported.

Replacing an image retains the old file so existing references are not broken. Automatic cleanup of unused uploads is not implemented.
