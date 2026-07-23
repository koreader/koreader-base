local ffi = require("ffi")

ffi.cdef[[
    typedef int avifBool;
    // AVIF_TRUE 1
    // AVIF_FALSE 0

    typedef enum {
        AVIF_RESULT_OK = 0,
        AVIF_RESULT_UNKNOWN_ERROR = 1,
        AVIF_RESULT_INVALID_FTYP = 2,
        AVIF_RESULT_NO_CONTENT = 3,
        AVIF_RESULT_NO_YUV_FORMAT_SELECTED = 4,
        AVIF_RESULT_REFORMAT_FAILED = 5,
        AVIF_RESULT_UNSUPPORTED_DEPTH = 6,
        AVIF_RESULT_ENCODE_COLOR_FAILED = 7,
        AVIF_RESULT_ENCODE_ALPHA_FAILED = 8,
        AVIF_RESULT_BMFF_PARSE_FAILED = 9,
        AVIF_RESULT_MISSING_IMAGE_ITEM = 10,
        AVIF_RESULT_DECODE_COLOR_FAILED = 11,
        AVIF_RESULT_DECODE_ALPHA_FAILED = 12,
        AVIF_RESULT_COLOR_ALPHA_SIZE_MISMATCH = 13,
        AVIF_RESULT_ISPE_SIZE_MISMATCH = 14,
        AVIF_RESULT_NO_CODEC_AVAILABLE = 15,
        AVIF_RESULT_NO_IMAGES_REMAINING = 16,
        AVIF_RESULT_INVALID_EXIF_PAYLOAD = 17,
        AVIF_RESULT_INVALID_IMAGE_GRID = 18,
        AVIF_RESULT_INVALID_CODEC_SPECIFIC_OPTION = 19,
        AVIF_RESULT_TRUNCATED_DATA = 20,
        AVIF_RESULT_IO_NOT_SET = 21,
        AVIF_RESULT_IO_ERROR = 22,
        AVIF_RESULT_WAITING_ON_IO = 23,
        AVIF_RESULT_INVALID_ARGUMENT = 24,
        AVIF_RESULT_NOT_IMPLEMENTED = 25,
        AVIF_RESULT_OUT_OF_MEMORY = 26,
        AVIF_RESULT_CANNOT_CHANGE_SETTING = 27,
        AVIF_RESULT_INCOMPATIBLE_IMAGE = 28,
        AVIF_RESULT_INTERNAL_ERROR = 29,
        AVIF_RESULT_ENCODE_GAIN_MAP_FAILED = 30,
        AVIF_RESULT_DECODE_GAIN_MAP_FAILED = 31,
        AVIF_RESULT_INVALID_TONE_MAPPED_IMAGE = 32,
        AVIF_RESULT_ENCODE_SAMPLE_TRANSFORM_FAILED = 33,
        AVIF_RESULT_DECODE_SAMPLE_TRANSFORM_FAILED = 34
    } avifResult;

    typedef enum {
        AVIF_PIXEL_FORMAT_NONE = 0,
        AVIF_PIXEL_FORMAT_YUV444,
        AVIF_PIXEL_FORMAT_YUV422,
        AVIF_PIXEL_FORMAT_YUV420,
        AVIF_PIXEL_FORMAT_YUV400,
        AVIF_PIXEL_FORMAT_COUNT
    } avifPixelFormat;

    typedef enum {
        AVIF_RANGE_LIMITED = 0,
        AVIF_RANGE_FULL = 1
    } avifRange;

    typedef struct {
        char error[256];
    } avifDiagnostics;

    typedef struct avifImage {
        uint32_t width;
        uint32_t height;
        uint32_t depth;
        avifPixelFormat yuvFormat;
        avifRange yuvRange;
        uint8_t * yuvPlanes[3];
        uint32_t yuvRowBytes[3];
        avifBool imageOwnsYUVPlanes;
        uint8_t * alphaPlane;
        uint32_t alphaRowBytes;
        avifBool imageOwnsAlphaPlane;
        avifBool alphaPremultiplied;
    } avifImage;

    typedef struct {
        uint32_t width;
        uint32_t height;
        uint32_t depth;
        int format; // avifRGBFormat
        int chromaUpsampling;
        avifBool avoidLibYUV;
        avifBool ignoreAlpha;
        avifBool alphaPremultiplied;
        int maxThreads;
        uint8_t * pixels;
        uint32_t rowBytes;
    } avifRGBImage;

    typedef struct avifDecoder {
        int codecChoice;
        int maxThreads;
        int requestedSource;
        avifBool allowProgressive;
        avifBool allowIncremental;
        avifBool ignoreExif;
        avifBool ignoreXMP;
        uint32_t imageSizeLimit;
        uint32_t imageDimensionLimit;
        uint32_t imageCountLimit;
        uint32_t strictFlags;
        avifImage * image;
        int imageIndex;
        int imageCount;
        int progressiveState;
        avifBool alphaPresent;
        avifDiagnostics diag;
    } avifDecoder;

    typedef struct avifIO {
        void (*destroy)(struct avifIO * io);
        int (*read)(struct avifIO * io, uint32_t readFlags, uint64_t offset, size_t size, void * out);
        void (*write)(struct avifIO * io, uint32_t writeFlags, uint64_t offset, const uint8_t * data, size_t size);
        uint64_t sizeHint;
        avifBool persistent;
        void * data;
    } avifIO;

    avifDecoder * avifDecoderCreate(void);
    void avifDecoderDestroy(avifDecoder * decoder);
    int avifDecoderParse(avifDecoder * decoder);
    int avifDecoderNextImage(avifDecoder * decoder);
    int avifDecoderSetIOMemory(avifDecoder * decoder, const uint8_t * data, size_t size);
    int avifDecoderSetIOFile(avifDecoder * decoder, const char * filename);
    int avifImageYUVToRGB(const avifImage * image, avifRGBImage * rgb);
    void avifRGBImageSetDefaults(avifRGBImage * rgb, const avifImage * image);
    int avifRGBImageAllocatePixels(avifRGBImage * rgb);
    void avifRGBImageFreePixels(avifRGBImage * rgb);
    int avifDecoderReadMemory(avifDecoder * decoder, avifImage * image, const uint8_t * data, size_t size);
    int avifDecoderReadFile(avifDecoder * decoder, avifImage * image, const char * filename);
    int avifDecoderRead(avifDecoder * decoder, avifImage * image);
    const char * avifResultToString(avifResult result);
]]
