open DynamicTableUtils
open NewThemeUtils
type sortTyp = ASC | DSC
type sortOb = {
  sortKey: string,
  sortType: sortTyp,
}

type checkBoxProps = {
  showCheckBox: bool,
  selectedData: array<JSON.t>,
  setSelectedData: (array<JSON.t> => array<JSON.t>) => unit,
}

let checkBoxPropDefaultVal: checkBoxProps = {
  showCheckBox: false,
  selectedData: [],
  setSelectedData: _ => (),
}

let sortAtom: Recoil.recoilAtom<Dict.t<sortOb>> = Recoil.atom("sortAtom", Dict.make())

let backgroundClass = "dark:bg-jp-gray-darkgray_background"

let useSortedObj = (title: string, defaultSort) => {
  let (dict, setDict) = Recoil.useRecoilState(sortAtom)
  let filters = Dict.get(dict, title)

  let (sortedObj, setSortedObj) = React.useState(_ => defaultSort)
  React.useEffect(() => {
    switch filters {
    | Some(filt) =>
      let sortObj: Table.sortedObject = {
        key: filt.sortKey,
        order: switch filt.sortType {
        | DSC => Table.DEC
        | _ => Table.INC
        },
      }
      setSortedObj(_ => Some(sortObj))
    | None => ()
    }

    None
  }, [])

  // Adding new
  React.useEffect(() => {
    switch sortedObj {
    | Some(obj: Table.sortedObject) =>
      let sortOb = {
        sortKey: obj.key,
        sortType: switch obj.order {
        | Table.DEC => DSC
        | _ => ASC
        },
      }

      setDict(dict => {
        let nDict = Dict.fromArray(Dict.toArray(dict))
        Dict.set(nDict, title, sortOb)
        nDict
      })
    | _ => ()
    }
    None
  }, [sortedObj])

  (sortedObj, setSortedObj)
}
let sortArray = (originalData, key, sortOrder: Table.sortOrder) => {
  let getValue = val => {
    switch val {
    | Some(x) =>
      switch x->JSON.Classify.classify {
      | String(str) => str->String.toLowerCase->JSON.Encode.string
      | Number(_num) => x
      | Bool(val) => val ? "true"->JSON.Encode.string : "false"->JSON.Encode.string
      | _ => ""->JSON.Encode.string
      }
    | None => ""->JSON.Encode.string
    }
  }
  let sortedArrayByOrder = {
    originalData->Array.toSorted((i1, i2) => {
      let item1 = i1->JSON.stringifyAny->Option.getOr("")->LogicUtils.safeParse
      let item2 = i2->JSON.stringifyAny->Option.getOr("")->LogicUtils.safeParse
      // flatten items and get data

      let val1 =
        JsonFlattenUtils.flattenObject(item1, true)
        ->JSON.Encode.object
        ->JSON.Decode.object
        ->Option.flatMap(dict => dict->Dict.get(key))
      let val2 =
        JsonFlattenUtils.flattenObject(item2, true)
        ->JSON.Encode.object
        ->JSON.Decode.object
        ->Option.flatMap(dict => dict->Dict.get(key))
      let value1 = getValue(val1)
      let value2 = getValue(val2)
      if value1 === ""->JSON.Encode.string || value2 === ""->JSON.Encode.string {
        if value1 === value2 {
          0.
        } else if value2 === ""->JSON.Encode.string {
          sortOrder === DEC ? 1. : -1.
        } else if sortOrder === DEC {
          -1.
        } else {
          1.
        }
      } else if value1 === value2 {
        0.
      } else if value1 > value2 {
        sortOrder === DEC ? 1. : -1.
      } else if sortOrder === DEC {
        -1.
      } else {
        1.
      }
    })
  }
  sortedArrayByOrder
}
type pageDetails = {
  offset: int,
  resultsPerPage: int,
}

let table_pageDetails: Recoil.recoilAtom<Dict.t<pageDetails>> = Recoil.atom(
  "table_pageDetails",
  Dict.make(),
)

@react.component
let make = (
  ~hideCustomisableColumnButton=false,
  ~visibleColumns=?,
  ~defaultSort=?,
  ~title,
  ~titleSize: NewThemeUtils.headingSize=Large,
  ~description=?,
  ~tableActions=?,
  ~isTableActionBesideFilters=false,
  ~hideFilterTopPortals=true,
  ~rightTitleElement=React.null,
  ~clearFormattedDataButton=?,
  ~bottomActions=?,
  ~showSerialNumber=false,
  ~actualData,
  ~totalResults,
  ~resultsPerPage,
  ~offset,
  ~setOffset,
  ~handleRefetch=?,
  ~entity: EntityType.entityType<'colType, 't>,
  ~onEntityClick=?,
  ~onEntityDoubleClick=?,
  ~onExpandClickData=?,
  ~currrentFetchCount,
  ~filters=?,
  ~showFilterBorder=false,
  ~headBottomMargin="mb-6 mobile:mb-4",
  ~removeVerticalLines: option<bool>=?,
  ~removeHorizontalLines=false,
  ~evenVertivalLines=false,
  ~showPagination=true,
  ~downloadCsv=?,
  ~ignoreUrlUpdate=false,
  ~hideTitle=false,
  ~ignoreHeaderBg=false,
  ~tableDataLoading=false,
  ~dataLoading=false,
  ~advancedSearchComponent=?,
  ~setData=?,
  ~setSummary=?,
  ~dataNotFoundComponent=?,
  ~renderCard=?,
  ~tableLocalFilter=false,
  ~tableheadingClass="",
  ~tableBorderClass="",
  ~tableDataBorderClass="",
  ~collapseTableRow=false,
  ~getRowDetails=?,
  ~onMouseEnter=?,
  ~onMouseLeave=?,
  ~frozenUpto=?,
  ~heightHeadingClass=?,
  ~highlightText="",
  ~enableEqualWidthCol=false,
  ~clearFormatting=false,
  ~rowHeightClass="",
  ~allowNullableRows=false,
  ~titleTooltip=false,
  ~isAnalyticsModule=false,
  ~rowCustomClass="",
  ~isHighchartLegend=false,
  ~filterObj=?,
  ~setFilterObj=?,
  ~headingCenter=false,
  ~filterIcon=?,
  ~filterDropdownClass=?,
  ~maxTableHeight="",
  ~showTableOnMobileView=false,
  ~labelMargin="",
  ~customFilterRowStyle="",
  ~noDataMsg="No Data Available",
  ~tableActionBorder="",
  ~isEllipsisTextRelative=true,
  ~customMoneyStyle="",
  ~ellipseClass="",
  ~checkBoxProps: checkBoxProps=checkBoxPropDefaultVal,
  ~selectedRowColor=?,
  ~paginationClass="",
  ~lastHeadingClass="",
  ~lastColClass="",
  ~fixLastCol=false,
  ~headerCustomBgColor=?,
  ~alignCellContent=?,
  ~minTableHeightClass="",
  ~setExtFilteredDataLength=?,
  ~filterDropdownMaxHeight=?,
  ~showResultsPerPageSelector=true,
  ~customCellColor=?,
  ~defaultResultsPerPage=true,
  ~noScrollbar=false,
  ~tableDataBackgroundClass="",
  ~customBorderClass=?,
  ~showborderColor=?,
  ~tableHeadingTextClass="",
  ~nonFrozenTableParentClass="",
  ~loadedTableParentClass="",
  ~remoteSortEnabled=false,
  ~showAutoScroll=false,
) => {
  open LogicUtils
  let showPopUp = PopUpState.useShowPopUp()
  React.useEffect(_ => {
    if title->isEmptyString && GlobalVars.isLocalhost {
      showPopUp({
        popUpType: (Denied, WithIcon),
        heading: `Title cannot be empty!`,
        description: React.string(`Please put valid title and use hideTitle prop to hide the title as offset recoil uses title`),
        handleConfirm: {text: "OK"},
      })
    }
    None
  }, [])

  let customizeColumnNewTheme = None
  let defaultValue: pageDetails = {offset, resultsPerPage}
  let (firstRender, setFirstRender) = React.useState(_ => true)
  let setPageDetails = Recoil.useSetRecoilState(table_pageDetails)
  let pageDetailDict = Recoil.useRecoilValueFromAtom(table_pageDetails)
  let pageDetail = pageDetailDict->Dict.get(title)->Option.getOr(defaultValue)

  let (
    selectAllCheckBox: option<TableUtils.multipleSelectRows>,
    setSelectAllCheckBox,
  ) = React.useState(_ => None)

  let newSetOffset = offsetVal => {
    let value = switch pageDetailDict->Dict.get(title) {
    | Some(val) => {offset: offsetVal(0), resultsPerPage: val.resultsPerPage}

    | None => {offset: offsetVal(0), resultsPerPage: defaultValue.resultsPerPage}
    }

    let newDict = pageDetailDict->Dict.toArray->Dict.fromArray

    newDict->Dict.set(title, value)
    setOffset(_ => offsetVal(0))
    setPageDetails(_ => newDict)
  }
  let url = RescriptReactRouter.useUrl()

  React.useEffect(_ => {
    setFirstRender(_ => false)
    setOffset(_ => pageDetail.offset)
    None
  }, [url.path->List.toArray->Array.joinWith("/")])

  React.useEffect(_ => {
    if pageDetail.offset !== offset && !firstRender {
      let value = switch pageDetailDict->Dict.get(title) {
      | Some(val) => {offset, resultsPerPage: val.resultsPerPage}
      | None => {offset, resultsPerPage: defaultValue.resultsPerPage}
      }

      let newDict = pageDetailDict->Dict.toArray->Dict.fromArray
      newDict->Dict.set(title, value)
      setPageDetails(_ => newDict)
    }
    None
  }, [offset])

  let setLocalResultsPerPageOrig = localResultsPerPage => {
    let value = switch pageDetailDict->Dict.get(title) {
    | Some(val) =>
      if totalResults > val.offset || tableDataLoading {
        {offset: val.offset, resultsPerPage: localResultsPerPage(0)}
      } else {
        {offset: 0, resultsPerPage}
      }
    | None => {offset: defaultValue.offset, resultsPerPage: localResultsPerPage(0)}
    }
    let newDict = pageDetailDict->Dict.toArray->Dict.fromArray

    newDict->Dict.set(title, value)
    setPageDetails(_ => newDict)
  }

  let (columnFilter, setColumnFilterOrig) = React.useState(_ => Dict.make())
  let isMobileView = MatchMedia.useMobileChecker()
  let url = RescriptReactRouter.useUrl()
  let dateFormatConvertor = useDateFormatConvertor()
  let (dataView, setDataView) = React.useState(_ =>
    isMobileView && !showTableOnMobileView ? Card : Table
  )

  let localResultsPerPage = pageDetail.resultsPerPage

  let setColumnFilter = React.useMemo(() => {
    (filterKey, filterValue: array<JSON.t>) => {
      setColumnFilterOrig(oldFitlers => {
        let newObj = oldFitlers->Dict.toArray->Dict.fromArray
        let filterValue = filterValue->Array.filter(
          item => {
            let updatedItem = item->String.make
            updatedItem->isNonEmptyString
          },
        )
        if filterValue->Array.length === 0 {
          newObj
          ->Dict.toArray
          ->Array.filter(
            entry => {
              let (key, _value) = entry
              key !== filterKey
            },
          )
          ->Dict.fromArray
        } else {
          Dict.set(newObj, filterKey, filterValue)
          newObj
        }
      })
    }
  }, [setColumnFilterOrig])

  React.useEffect(_ => {
    if columnFilter != Dict.make() {
      newSetOffset(_ => 0)
    }
    None
  }, [columnFilter])

  let filterValue = React.useMemo(() => {
    (columnFilter, setColumnFilter)
  }, (columnFilter, setColumnFilter))

  let (isFilterOpen, setIsFilterOpenOrig) = React.useState(_ => Dict.make())
  let setIsFilterOpen = React.useMemo(() => {
    (filterKey, value: bool) => {
      setIsFilterOpenOrig(oldFitlers => {
        let newObj = oldFitlers->DictionaryUtils.copyOfDict
        newObj->Dict.set(filterKey, value)
        newObj
      })
    }
  }, [setColumnFilterOrig])
  let filterOpenValue = React.useMemo(() => {
    (isFilterOpen, setIsFilterOpen)
  }, (isFilterOpen, setIsFilterOpen))

  let heading = visibleColumns->Option.getOr(entity.defaultColumns)->Array.map(entity.getHeading)

  let handleRemoveLines = removeVerticalLines->Option.getOr(true)
  if showSerialNumber {
    heading
    ->Array.unshift(
      Table.makeHeaderInfo(~key="serial_number", ~title="S.No", ~dataType=NumericType),
    )
    ->ignore
  }

  if checkBoxProps.showCheckBox {
    heading
    ->Array.unshift(Table.makeHeaderInfo(~key="select", ~title="", ~showMultiSelectCheckBox=true))
    ->ignore
  }

  let setLocalResultsPerPage = React.useCallback(fn => {
    setLocalResultsPerPageOrig(prev => {
      let newVal = prev->fn
      if newVal == 0 {
        localResultsPerPage
      } else {
        newVal
      }
    })
  }, [setLocalResultsPerPageOrig])

  let {getShowLink, searchFields, searchUrl} = entity
  let (sortedObj, setSortedObj) = useSortedObj(title, defaultSort)

  React.useEffect(() => {
    setDataView(_prev => isMobileView && !showTableOnMobileView ? Card : Table)
    None
  }, [isMobileView])

  let defaultOffset = totalResults / localResultsPerPage * localResultsPerPage

  let offsetVal = offset < totalResults ? offset : defaultOffset
  let offsetVal = ignoreUrlUpdate ? offset : offsetVal

  React.useEffect(() => {
    if offset > currrentFetchCount && offset <= totalResults && !tableDataLoading {
      switch handleRefetch {
      | Some(fun) => fun()
      | None => ()
      }
    }
    None
  }, (offset, currrentFetchCount, totalResults, tableDataLoading))

  let originalActualData = actualData
  let actualData = React.useMemo(() => {
    if tableLocalFilter {
      filteredData(actualData, columnFilter, visibleColumns, entity, dateFormatConvertor)
    } else {
      actualData
    }
  }, (actualData, columnFilter, visibleColumns, entity, dateFormatConvertor))

  let columnFilterRow = React.useMemo(() => {
    if tableLocalFilter {
      let columnFilterRow =
        visibleColumns
        ->Option.getOr(entity.defaultColumns)
        ->Array.map(item => {
          let headingEntity = entity.getHeading(item)
          let key = headingEntity.key
          let dataType = headingEntity.dataType
          let filterValueArray = []
          let columnFilterCopy = columnFilter->DictionaryUtils.deleteKey(key)

          let actualData =
            columnFilter->Dict.keysToArray->Array.includes(headingEntity.key)
              ? originalActualData
              : actualData

          actualData
          ->filteredData(columnFilterCopy, visibleColumns, entity, dateFormatConvertor)
          ->Array.forEach(
            rows => {
              switch rows->Nullable.toOption {
              | Some(rows) =>
                let value = switch entity.getCell(rows, item) {
                | CustomCell(_, str)
                | DisplayCopyCell(str)
                | EllipsisText(str, _)
                | Link(str)
                | Date(str)
                | DateWithoutTime(str)
                | DateWithCustomDateStyle(str, _)
                | Text(str) =>
                  convertStrCellToFloat(dataType, str)
                | Label(x)
                | ColoredText(x) =>
                  convertStrCellToFloat(dataType, x.title)
                | DeltaPercentage(num, _) | Currency(num, _) | Numeric(num, _) =>
                  convertFloatCellToStr(dataType, num)
                | Progress(num) => convertFloatCellToStr(dataType, num->Int.toFloat)
                | StartEndDate(_) | InputField(_) | TrimmedText(_) | DropDown(_) =>
                  convertStrCellToFloat(dataType, "")
                }
                filterValueArray->Array.push(value)->ignore
              | None => ()
              }
            },
          )

          switch dataType {
          | DropDown => Table.DropDownFilter(key, filterValueArray) // TextDropDownColumn
          | LabelType | TextType => Table.TextFilter(key)
          | MoneyType | NumericType | ProgressType => {
              let newArr =
                filterValueArray->Array.map(item => item->JSON.Decode.float->Option.getOr(0.))

              if newArr->Array.length >= 1 {
                Table.Range(key, Math.minMany(newArr), Math.maxMany(newArr))
              } else {
                Table.Range(key, 0.0, 0.0)
              }
            }
          }
        })

      Some(
        showSerialNumber && tableLocalFilter
          ? Array.concat(
              [Table.Range("s_no", 0., actualData->Array.length->Int.toFloat)],
              columnFilterRow,
            )
          : columnFilterRow,
      )
    } else {
      None
    }
  }, (actualData, totalResults, visibleColumns, columnFilter))

  let filteredDataLength =
    columnFilter->Dict.keysToArray->Array.length !== 0 ? actualData->Array.length : totalResults

  React.useEffect(() => {
    switch setExtFilteredDataLength {
    | Some(fn) => fn(_ => filteredDataLength)
    | _ => ()
    }
    None
  }, [filteredDataLength])

  let filteredData = React.useMemo(() => {
    if !remoteSortEnabled {
      switch sortedObj {
      | Some(obj: Table.sortedObject) => sortArray(actualData, obj.key, obj.order)
      | None => actualData
      }
    } else {
      actualData
    }
  }, (sortedObj, actualData))

  React.useEffect(() => {
    let selectedRowDataLength = checkBoxProps.selectedData->Array.length
    let isCompleteDataSelected = selectedRowDataLength === filteredData->Array.length
    if isCompleteDataSelected {
      setSelectAllCheckBox(_ => Some(ALL))
    } else if checkBoxProps.selectedData->Array.length === 0 {
      setSelectAllCheckBox(_ => None)
    } else {
      setSelectAllCheckBox(_ => Some(PARTIAL))
    }

    None
  }, (checkBoxProps.selectedData, filteredData))

  React.useEffect(() => {
    if selectAllCheckBox === Some(ALL) {
      checkBoxProps.setSelectedData(_ => {
        filteredData->Array.map(
          ele => {
            ele->Identity.nullableOfAnyTypeToJsonType
          },
        )
      })
    } else if selectAllCheckBox === None {
      checkBoxProps.setSelectedData(_ => [])
    }
    None
  }, [selectAllCheckBox])

  let sNoArr = Dict.get(columnFilter, "s_no")->Option.getOr([])
  // filtering for SNO
  let nullableRows = filteredData->Array.mapWithIndex((nullableItem, index) => {
    let actualRows = switch nullableItem->Nullable.toOption {
    | Some(item) => {
        let visibleCell =
          visibleColumns
          ->Option.getOr(entity.defaultColumns)
          ->Array.map(colType => {
            entity.getCell(item, colType)
          })
        let startPoint = sNoArr->Array.get(0)->Option.getOr(1.->JSON.Encode.float)
        let endPoint = sNoArr->Array.get(1)->Option.getOr(1.->JSON.Encode.float)
        let jsonIndex = (index + 1)->Int.toFloat->JSON.Encode.float
        sNoArr->Array.length > 0
          ? {
              startPoint <= jsonIndex && endPoint >= jsonIndex ? visibleCell : []
            }
          : visibleCell
      }

    | None => []
    }

    let setIsSelected = isSelected => {
      if isSelected {
        checkBoxProps.setSelectedData(prev =>
          prev->Array.concat([nullableItem->Identity.nullableOfAnyTypeToJsonType])
        )
      } else {
        checkBoxProps.setSelectedData(prev =>
          prev->Array.filter(item => item !== nullableItem->Identity.nullableOfAnyTypeToJsonType)
        )
      }
    }

    if actualRows->Array.length > 0 {
      if showSerialNumber {
        actualRows
        ->Array.unshift(
          Numeric(
            (1 + index)->Int.toFloat,
            (val: float) => {
              val->Float.toString
            },
          ),
        )
        ->ignore
      }
      if checkBoxProps.showCheckBox {
        let selectedRowIndex =
          checkBoxProps.selectedData->Array.findIndex(item =>
            item === nullableItem->Identity.nullableOfAnyTypeToJsonType
          )
        actualRows
        ->Array.unshift(
          CustomCell(
            <div onClick={ev => ev->ReactEvent.Mouse.stopPropagation}>
              <CheckBoxIcon
                isSelected={selectedRowIndex !== -1} setIsSelected checkboxDimension="h-4 w-4"
              />
            </div>,
            (selectedRowIndex !== -1)->getStringFromBool,
          ),
        )
        ->ignore
      }
    }

    actualRows
  })

  let rows = if allowNullableRows {
    nullableRows
  } else {
    nullableRows->Belt.Array.keepMap(item => {
      item->Array.length == 0 ? None : Some(item)
    })
  }

  let paginatedData =
    filteredData->Array.slice(~start=offsetVal, ~end={offsetVal + localResultsPerPage})
  let rows = rows->Array.slice(~start=offsetVal, ~end={offsetVal + localResultsPerPage})

  let handleRowClick = React.useCallback(index => {
    let actualVal = switch filteredData[index] {
    | Some(ele) => ele->Nullable.toOption
    | None => None
    }
    switch actualVal {
    | Some(value) =>
      switch onEntityClick {
      | Some(fn) => fn(value)
      | None =>
        switch getShowLink {
        | Some(fn) => {
            let link = fn(value)
            let finalUrl = url.search->isNonEmptyString ? `${link}?${url.search}` : link
            RescriptReactRouter.push(finalUrl)
          }

        | None => ()
        }
      }
    | None => ()
    }
  }, (filteredData, getShowLink, onEntityClick, url.search))

  let onRowDoubleClick = React.useCallback(index => {
    let actualVal = switch filteredData[index] {
    | Some(ele) => ele->Nullable.toOption
    | None => None
    }
    switch actualVal {
    | Some(value) =>
      switch onEntityDoubleClick {
      | Some(fn) => fn(value)
      | None =>
        switch getShowLink {
        | Some(fn) => {
            let link = fn(value)
            let finalUrl = url.search->isNonEmptyString ? `${link}?${url.search}` : link
            RescriptReactRouter.push(finalUrl)
          }

        | None => ()
        }
      }
    | None => ()
    }
  }, (filteredData, getShowLink, onEntityDoubleClick, url.search))

  let handleMouseEnter = React.useCallback(index => {
    let actualVal = switch filteredData[index] {
    | Some(ele) => ele->Nullable.toOption
    | None => None
    }
    switch actualVal {
    | Some(value) =>
      switch onMouseEnter {
      | Some(fn) => fn(value)
      | None => ()
      }
    | None => ()
    }
  }, (filteredData, getShowLink, onMouseEnter, url.search))

  let handleMouseLeaeve = React.useCallback(index => {
    let actualVal = switch filteredData[index] {
    | Some(ele) => ele->Nullable.toOption
    | None => None
    }
    switch actualVal {
    | Some(value) =>
      switch onMouseLeave {
      | Some(fn) => fn(value)
      | None => ()
      }
    | None => ()
    }
  }, (filteredData, getShowLink, onMouseLeave, url.search))

  let filterBottomPadding = isMobileView ? "" : "pb-4"

  let paddingClass = {rightTitleElement != React.null ? filterBottomPadding : ""}

  let customizeColumsButtons = {
    switch clearFormattedDataButton {
    | Some(clearFormattedDataButton) =>
      <div className={`flex flex-row mobile:gap-7 desktop:gap-10 ${filterBottomPadding}`}>
        clearFormattedDataButton
        {rightTitleElement}
      </div>
    | _ => <div className={paddingClass}> {rightTitleElement} </div>
    }
  }

  let (loadedTableUI, paginationUI) = if totalResults > 0 {
    let paginationUI = if showPagination {
      <AddDataAttributes attributes=[("data-paginator", "dynamicTablePaginator")]>
        <Paginator
          totalResults=filteredDataLength
          offset=offsetVal
          resultsPerPage=localResultsPerPage
          setOffset=newSetOffset
          ?handleRefetch
          currrentFetchCount
          ?downloadCsv
          actualData
          tableDataLoading
          setResultsPerPage=setLocalResultsPerPage
          paginationClass
          showResultsPerPageSelector
        />
      </AddDataAttributes>
    } else {
      React.null
    }
    let isMinHeightRequired =
      noScrollbar || (tableLocalFilter && rows->Array.length <= 5 && frozenUpto->Option.isNone)

    let scrollBarClass =
      isFilterOpen->Dict.valuesToArray->Array.reduce(false, (acc, item) => item || acc)
        ? ""
        : `${isMinHeightRequired ? noScrollbar ? "" : "overflow-x-scroll" : "overflow-scroll"}`
    let loadedTable =
      <div className={`no-scrollbar ${scrollBarClass}`}>
        {switch dataView {
        | Table => {
            let children =
              <Table
                title
                heading
                rows
                ?filterObj
                ?setFilterObj
                onRowClick=handleRowClick
                onRowDoubleClick
                onRowClickPresent={onEntityClick->Option.isSome || getShowLink->Option.isSome}
                offset=offsetVal
                setSortedObj
                ?sortedObj
                removeVerticalLines=handleRemoveLines
                evenVertivalLines
                ?columnFilterRow
                tableheadingClass
                tableBorderClass
                tableDataBorderClass
                enableEqualWidthCol
                collapseTableRow
                ?getRowDetails
                ?onExpandClickData
                actualData
                onMouseEnter=handleMouseEnter
                onMouseLeave=handleMouseLeaeve
                highlightText
                clearFormatting
                ?heightHeadingClass
                ?frozenUpto
                rowHeightClass
                isMinHeightRequired
                rowCustomClass
                isHighchartLegend
                headingCenter
                ?filterIcon
                ?filterDropdownClass
                maxTableHeight
                labelMargin
                customFilterRowStyle
                ?selectAllCheckBox
                setSelectAllCheckBox
                isEllipsisTextRelative
                customMoneyStyle
                ellipseClass
                ?selectedRowColor
                lastHeadingClass
                showCheckbox={checkBoxProps.showCheckBox}
                lastColClass
                fixLastCol
                ?headerCustomBgColor
                ?alignCellContent
                ?customCellColor
                minTableHeightClass
                ?filterDropdownMaxHeight
                ?customizeColumnNewTheme
                removeHorizontalLines
                ?customBorderClass
                ?showborderColor
                tableHeadingTextClass
                nonFrozenTableParentClass
                showAutoScroll
                showPagination
              />
            switch tableLocalFilter {
            | true =>
              <DatatableContext value={filterValue}>
                <DataTableFilterOpenContext value={filterOpenValue}>
                  children
                </DataTableFilterOpenContext>
              </DatatableContext>
            | false => children
            }
          }

        | Card =>
          switch renderCard {
          | Some(renderer) =>
            <div className="overflow-auto flex flex-col">
              {paginatedData
              ->Belt.Array.keepMap(Nullable.toOption)
              ->Array.mapWithIndex((item, rowIndex) => {
                renderer(~index={rowIndex + offset}, ~item, ~onRowClick=handleRowClick)
              })
              ->React.array}
            </div>
          | None =>
            <CardTable heading rows onRowClick=handleRowClick offset=offsetVal isAnalyticsModule />
          }
        }}
      </div>

    (loadedTable, paginationUI)
  } else if totalResults === 0 && !tableDataLoading {
    let noDataTable = switch dataNotFoundComponent {
    | Some(comp) => comp
    | None => <NoDataFound customCssClass={"my-6"} message=noDataMsg renderType=Painting />
    }
    (noDataTable, React.null)
  } else {
    (React.null, React.null)
  }

  let tableActionBorder = if !isMobileView {
    if showFilterBorder {
      "p-2 bg-white dark:bg-black border border-jp-2-light-gray-400 rounded-lg"
    } else {
      ""
    }
  } else {
    tableActionBorder
  }

  let filtersOuterMargin = if hideTitle {
    ""
  } else {
    "my-2"
  }

  let tableActionElements =
    <div className="flex flex-row">
      {switch advancedSearchComponent {
      | Some(x) =>
        <AdvancedSearchComponent entity ?setData ?setSummary> {x} </AdvancedSearchComponent>
      | None =>
        <RenderIf condition={searchFields->Array.length > 0}>
          <AdvancedSearchModal searchFields url=searchUrl entity />
        </RenderIf>
      }}
      {switch tableActions {
      | Some(actions) =>
        <LoadedTableContext value={actualData->LoadedTableContext.toInfoData}>
          <div className=filterBottomPadding> actions </div>
        </LoadedTableContext>
      | None => React.null
      }}
    </div>

  let addDataAttributesClass = if isHighchartLegend {
    `visibility: hidden`
  } else {
    `${ignoreHeaderBg ? "" : backgroundClass} empty:hidden`
  }
  let dataId = title->String.split("-")->Array.get(0)->Option.getOr("")
  <AddDataAttributes attributes=[("data-loaded-table", dataId)]>
    <div className={`w-full ${loadedTableParentClass}`}>
      <div className=addDataAttributesClass style={zIndex: "2"}>
        //removed "sticky" -> to be tested with master
        <div
          className={`flex flex-row justify-between items-center` ++ (
            hideTitle ? "" : ` mt-4 mb-2`
          )}>
          <div className="w-full">
            <RenderIf condition={!hideTitle}>
              <NewThemeHeading
                headingColor="text-nd_gray-600"
                heading=title
                headingSize=titleSize
                outerMargin=""
                ?description
                rightActions={<RenderIf condition={!isMobileView && !isTableActionBesideFilters}>
                  {tableActionElements}
                </RenderIf>}
              />
            </RenderIf>
          </div>
        </div>
        <RenderIf condition={!hideFilterTopPortals}>
          <div className="flex justify-between items-center">
            <PortalCapture
              key={`tableFilterTopLeft-${title}`}
              name={`tableFilterTopLeft-${title}`}
              customStyle="flex items-center gap-x-2"
            />
            <PortalCapture
              key={`tableFilterTopRight-${title}`}
              name={`tableFilterTopRight-${title}`}
              customStyle="flex flex-row-reverse items-center gap-x-2"
            />
          </div>
        </RenderIf>
        <div
          className={`flex flex-row mobile:flex-wrap items-center ${tableActionBorder} ${filtersOuterMargin}`}>
          <TableFilterSectionContext isFilterSection=true>
            <div className={`flex-1 ${tableDataBackgroundClass}`}>
              {switch filters {
              | Some(filterSection) =>
                filterSection->React.Children.map(element => {
                  if element === React.null {
                    React.null
                  } else {
                    <div className=filterBottomPadding> element </div>
                  }
                })

              | None => React.null
              }}
              <PortalCapture key={`extraFilters-${title}`} name={`extraFilters-${title}`} />
            </div>
          </TableFilterSectionContext>
          <RenderIf condition={isTableActionBesideFilters || isMobileView || hideTitle}>
            {tableActionElements}
          </RenderIf>
          <RenderIf condition={!hideCustomisableColumnButton}> customizeColumsButtons </RenderIf>
        </div>
      </div>
      {if dataLoading {
        <TableDataLoadingIndicator showWithData={rows->Array.length !== 0} />
      } else {
        loadedTableUI
      }}
      <RenderIf condition={tableDataLoading && !dataLoading}>
        <TableDataLoadingIndicator showWithData={rows->Array.length !== 0} />
      </RenderIf>
      <div
        className={`${tableActions->Option.isSome && isMobileView
            ? `flex flex-row-reverse justify-between mb-10 ${tableDataBackgroundClass}`
            : tableDataBackgroundClass}`}>
        paginationUI
        {
          let topBottomActions = if bottomActions->Option.isSome {
            bottomActions
          } else {
            None
          }

          switch topBottomActions {
          | Some(actions) =>
            <LoadedTableContext value={actualData->LoadedTableContext.toInfoData}>
              actions
            </LoadedTableContext>

          | None => React.null
          }
        }
      </div>
    </div>
  </AddDataAttributes>
}
