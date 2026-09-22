package com.caffora.backend.controller;

import com.caffora.backend.exception.BadRequestException;
import com.caffora.backend.exception.ResourceNotFoundException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import javax.imageio.ImageIO;
import javax.imageio.stream.ImageInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/images")
public class ImageController {
    private final Path directory;

    public ImageController(@Value("${caffora.upload-directory:./uploads}") String directory) {
        this.directory = Path.of(directory).toAbsolutePath().normalize();
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Map<String, String> upload(@RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty() || file.getSize() > 5 * 1024 * 1024) {
            throw new BadRequestException("Choose an image smaller than 5 MB.");
        }
        // Decode and re-encode rather than trusting the filename or declared MIME type.
        try (ImageInputStream input = ImageIO.createImageInputStream(file.getInputStream())) {
            var readers = ImageIO.getImageReaders(input);
            if (!readers.hasNext()) throw new BadRequestException("Choose a valid JPEG or PNG image.");
            var reader = readers.next();
            try {
                String format = reader.getFormatName();
                if (!format.equalsIgnoreCase("JPEG") && !format.equalsIgnoreCase("PNG")) {
                    throw new BadRequestException("Only JPEG and PNG images are supported.");
                }
                reader.setInput(input);
                if ((long) reader.getWidth(0) * reader.getHeight(0) > 16_000_000) {
                    throw new BadRequestException("Image must be at most 16 megapixels.");
                }
                var image = reader.read(0);
                Files.createDirectories(directory);
                String name = UUID.randomUUID() + ".png";
                ImageIO.write(image, "png", directory.resolve(name).toFile());
                String url = ServletUriComponentsBuilder.fromCurrentRequestUri()
                        .path("/{name}").buildAndExpand(name).toUriString();
                return Map.of("imageUrl", url);
            } finally {
                reader.dispose();
            }
        } catch (javax.imageio.IIOException ex) {
            throw new BadRequestException("The image is damaged or cannot be read.");
        }
    }

    @GetMapping("/{name}")
    public ResponseEntity<Resource> image(@PathVariable String name) {
        if (!name.matches("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.png")) {
            throw new ResourceNotFoundException("Image not found");
        }
        Path path = directory.resolve(name);
        if (!Files.isRegularFile(path)) throw new ResourceNotFoundException("Image not found");
        return ResponseEntity.ok().contentType(MediaType.IMAGE_PNG).body(new FileSystemResource(path));
    }
}
