#' @title Calculate file size
#'
#' @description \code{file_size} takes a filepath and an optional regular
#' expression pattern. It returns the size of all files within that directory
#' which match the given pattern.
#'
#' @details The sizes of files with certain extensions are returned with the
#' type of file prefixed. For example, the size of a 12 KB \code{.xlsx} file is
#' returned as `Excel 12 KB`. The complete list of explicitly catered-for file
#' extensions and their prefixes are as follows:
#'
#' \itemize{
#' \item \code{.xls}, \code{.xlsb}, \code{.xlsm} and \code{.xlsx} files are
#' prefixed with `Excel`
#' \item \code{.csv} files are prefixed with `CSV`
#' \item \code{.sav} and \code{.zsav} files are prefixed with `SPSS`
#' \item \code{.doc}, \code{.docm} and \code{.docx} files are prefixed with
#' `Word`
#' \item \code{.rds} files are prefixed with `RDS`
#' \item \code{.txt} files are prefixed with `Text`,
#' \item \code{.fst} files are prefixed with `FST`,
#' \item \code{.pdf} files are prefixed with `PDF`,
#' \item \code{.tsv} files are prefixed with `TSV`,
#' \item \code{.html} files are prefixed with `HTML`,
#' \item \code{.ppt}, \code{.pptm} and \code{.pptx} files are prefixed with
#' `PowerPoint`,
#' \item \code{.md} files are prefixed with `Markdown`
#' }
#'
#' Files with extensions not contained within this list will have their size
#' returned with no prefix. To request that a certain extension be explicitly
#' catered for, please create an issue on
#' \href{https://github.com/Health-SocialCare-Scotland/phsmethods/issues}{GitHub}.
#'
#' File sizes are returned as the appropriate multiple of the unit byte
#' (bytes (B), kilobytes (KB), megabytes (MB), etc.). Each multiple is taken to
#' be 1,024 units of the preceding denomination.
#'
#' @param filepath A character string denoting a filepath. Defaults to the
#' working directory, \code{getwd()}.
#' @param pattern An optional character string denoting a
#' \code{\link[base:regex]{regular expression}} pattern. Only file names which
#' match the regular expression will be returned. See the \strong{See Also}
#' section for resources regarding how to write regular expressions.
#'
#' @return A \code{\link[tibble]{tibble}} listing the names of files within
#' \code{filepath} which match \code{pattern} and their respective sizes. The
#' column names of this tibble are `name` and `size`. If no \code{pattern} is
#' specified, \code{file_size} returns the names and sizes of all files within
#' \code{filepath}. File names and sizes are returned in alphabetical order of
#' file name. Sub-folders contained within \code{filepath} will return a file
#' size of `0 B`.
#'
#' If \code{filepath} is an empty folder, or \code{pattern} matches no files
#' within \code{filepath}, \code{file_size} returns \code{NULL}.
#'
#' @examples
#' # Name and size of all files in working directory
#' file_size()
#'
#' # Name and size of .xlsx files only in working directory
#' file_size(pattern = ".xlsx$")
#'
#' # Size only of alphabetically first file in working directory
#' library(magrittr)
#' file_size() %>% dplyr::pull(size) %>% extract(1)
#'
#' @seealso For more information on using regular expressions, see this
#' \href{https://www.jumpingrivers.com/blog/regular-expressions-every-r-programmer-should-know/}{Jumping Rivers blog post}
#' and this
#' \href{https://stringr.tidyverse.org/articles/regular-expressions.html}{vignette}
#' from the \code{\link[stringr:stringr-package]{stringr}} package.
#'
#' @export

file_size <- function(filepath = getwd(), pattern = NULL) {

  if (!file.exists(filepath)) {
    stop("A valid filepath must be supplied")
  }

  if (!inherits(pattern, c("character", "NULL"))) {
    stop("A specified pattern must be of character class in order to be ",
         "evaluated as a regular expression")
  }

  x <- dir(path = filepath, pattern = pattern)

  if (length(x) == 0) {
    return(NULL)
  }

  y <- x %>%
    purrr::map(~file.info(paste0(filepath, "/", .))$size) %>%
    unlist() %>%

    # The gdata package defines a kilobyte (KB) as 1,000 bytes, and a
    # kibibyte (KiB) as 1,024 bytes
    # In PHS a kilobyte is normally taken to be 1,024 bytes
    # As a workaround, calculate file sizes in kibibytes (or higher), then
    # drop the `i` from the output
    gdata::humanReadable(standard = "IEC", digits = 0) %>%
    gsub("i", "", .) %>%
    trimws()

  z <- dplyr::case_when(
    stringr::str_detect(x, "\\.xls(b|m|x)?$") ~ "Excel ",
    stringr::str_detect(x, "\\.csv$") ~ "CSV ",
    stringr::str_detect(x, "\\.z?sav$") ~ "SPSS ",
    stringr::str_detect(x, "\\.doc(m|x)?$") ~ "Word ",
    stringr::str_detect(x, "\\.rds$") ~ "RDS ",
    stringr::str_detect(x, "\\.txt$") ~ "Text ",
    stringr::str_detect(x, "\\.fst$") ~ "FST ",
    stringr::str_detect(x, "\\.pdf$") ~ "PDF ",
    stringr::str_detect(x, "\\.tsv$") ~ "TSV ",
    stringr::str_detect(x, "\\.html$") ~ "HTML ",
    stringr::str_detect(x, "\\.ppt(m|x)?$") ~ "PowerPoint ",
    stringr::str_detect(x, "\\.md$") ~ "Markdown ",
    TRUE ~ ""
  )

  tibble::tibble(name = list.files(filepath, pattern),
                 size = paste0(z, y))

}
