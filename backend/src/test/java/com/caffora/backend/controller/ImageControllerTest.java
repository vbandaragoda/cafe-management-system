package com.caffora.backend.controller;

import com.caffora.backend.exception.BadRequestException;
import com.caffora.backend.exception.ResourceNotFoundException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.nio.file.Path;
import static org.junit.jupiter.api.Assertions.*;

class ImageControllerTest {
    @TempDir Path directory;

    @Test void storesAndServesDecodedImage() throws Exception {
        var controller = new ImageController(directory.toString());
        var bytes = new ByteArrayOutputStream();
        ImageIO.write(new BufferedImage(2, 2, BufferedImage.TYPE_INT_RGB), "png", bytes);
        var request = new MockHttpServletRequest();
        request.setRequestURI("/api/images");
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
        try {
            String url = controller.upload(new MockMultipartFile("file", "../../photo.png", "image/png", bytes.toByteArray())).get("imageUrl");
            String name = url.substring(url.lastIndexOf('/') + 1);
            var response = controller.image(name);
            assertTrue(response.getBody().exists());
            assertEquals(2, ImageIO.read(response.getBody().getFile()).getWidth());
            assertEquals("image/png", response.getHeaders().getContentType().toString());
        } finally {
            RequestContextHolder.resetRequestAttributes();
        }
    }

    @Test void rejectsInvalidEmptyOversizedAndTraversalInputs() {
        var controller = new ImageController(directory.toString());
        assertThrows(BadRequestException.class, () -> controller.upload(new MockMultipartFile("file", "fake.png", "image/png", "not an image".getBytes())));
        assertThrows(BadRequestException.class, () -> controller.upload(new MockMultipartFile("file", new byte[0])));
        assertThrows(BadRequestException.class, () -> controller.upload(new MockMultipartFile("file", new byte[5 * 1024 * 1024 + 1])));
        assertThrows(ResourceNotFoundException.class, () -> controller.image("../application.yml"));
    }
}
