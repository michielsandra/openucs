install(FILES
    Makefile.srcs
    DESTINATION ${PROJECT_DATA_DIR}/fpga
    COMPONENT fpga
)

add_subdirectory(rfnoc_block_sounder_rx)

