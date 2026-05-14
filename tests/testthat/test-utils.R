describe("concatenate hashes", {
  it("produces same value when one hash is '' as if it was raw(0)", {
    hash1 = raw(0)
    hash2 = as.raw(c(1, 1))
    res1 = .concatenate_hashes(hash1, hash2)
    res2 = .concatenate_hashes("", hash2)

    # Assert
    expect_identical(res1, res2)
  })
})
